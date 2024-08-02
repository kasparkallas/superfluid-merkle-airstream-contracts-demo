// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

import "./interfaces/IERC20.sol";
import "./MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";
import "./interfaces/IVestingSchedulerV2.sol";
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";

contract MerkleDistributor is IMerkleDistributor {
    using SuperTokenV1Library for ISuperToken;

    address public immutable override token;
    bytes32 public immutable override merkleRoot;

    uint256 public constant ONE_YEAR_IN_SECONDS = 31_536_000;
    uint256 public immutable activationTimestamp;
    address public immutable airdropTreasury;
    bool public isActive;

    IVestingSchedulerV2 public vestingScheduler;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    event Finalised(
        address indexed calledBy,
        uint256 timestamp,
        uint256 unclaimedAmount
    );

    constructor(
        address token_,
        bytes32 merkleRoot_,
        address _treasury,
        IVestingSchedulerV2 vestingScheduler_
    ) {
        token = token_;
        merkleRoot = merkleRoot_;
        vestingScheduler = vestingScheduler_;

        activationTimestamp = block.timestamp;
        isActive = true;
        airdropTreasury = _treasury;

        // # ACL allowance
        // "ACL" stands for "Access Control List" which is a permission system for flows (aka "streams"), built into the Superfluid Protocol.
        // Read more about it here: https://docs.superfluid.finance/docs/protocol/advanced-topics/advanced-money-streaming/access-control-list
        // What we're doing here is giving vesting scheduler the permission to create and delete flows on behalf of this contract.
        // In other words, the vesting scheduler acts as an operator on behalf of this contract, following the rules in the scheduler contract.

        // (address flowOperator, bool allowCreate, bool allowUpdate, bool allowDelete, int96 flowRateAllowance)
        ISuperToken(token).setFlowPermissions(address(vestingScheduler_), true, false, true, type(int96).max);

        // # ERC-20 allowance
        // The ERC-20 allowance is needed by the vesting scheduler to do so-called compensation amount and remainder amount transfers.
        // To clarify, the Superfluid flows are stored as integers, not fractions, and the flows keep flowing until they're actively deleted.
        // In case of the vesting scheduler, the flows are deleted by off-chain automation system,
        // and it can't be guaranteed to trigger at the perfect block.
        // So in a nutshell, the solution is to delete the flow slightly before the expected end date,
        // and use an ERC-20 transfer to compensate for the slightly early end and non-perfect divisibility of the integer flow rate.
        ISuperToken(token).approve(address(vestingScheduler_), type(uint256).max);

        // NOTE: We somewhat lazily give maximum allowances (for both ACL and token allowance), we could give less,
        // but the functioning of this contract is so reliant and coupled to the vesting scheduler that it doesn't really matter.
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // # Verify the merkle proof.
        // This used to be: `bytes32 node = keccak256(abi.encodePacked(index, account, amount));`
        // But I changed it to use double-hashing which is a slightly more modern and secure way of doing the proofing:
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(index, account, amount))));

        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);

        // This is a snippet of old code what happened here previously (now replaced with creating a Superfluid vesting schedule):
        // `require(
        //     IERC20(token).transfer(account, amount),
        //     "MerkleDistributor: Transfer failed."
        // );`

        // # Create and execute the vesting schedule
        ISuperToken superToken = ISuperToken(token); // For example: OPx
        uint32 vestingScheduleDuration = uint32(7 days); // An arbitrary value chosen for the demo.
        vestingScheduler.createAndExecuteVestingScheduleFromAmountAndDuration(superToken, account, amount, vestingScheduleDuration);

        emit Claimed(index, account, amount);

        // NOTE: if something happens to the flow/stream, this can't be re-triggered.
    }

    /**
     * @dev Finalises the airdrop and sweeps unclaimed tokens into the Optimism multisig
     */
    function clawBack() external {
        // Airdrop can only be finalised once
        require(isActive, "Airdrop: Already finalised");
        // Airdrop will remain open for one year
        require(
            block.timestamp >= activationTimestamp + ONE_YEAR_IN_SECONDS,
            "Airdrop: Drop should remain open for one year"
        );
        // Deactivate airdrop
        isActive = false;

        // Sweep unclaimed tokens
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(
            IERC20(token).transfer(airdropTreasury, amount),
            "Airdrop: Finalise transfer failed"
        );

        emit Finalised(msg.sender, block.timestamp, amount);
    }
}