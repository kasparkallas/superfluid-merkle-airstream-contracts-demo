// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

import "./interfaces/IVestingSchedulerV2.sol";
import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { MerkleDistributor } from "./MerkleDistributor.sol";

contract MerkleDistributorFactory {
    event Created(MerkleDistributor indexed distributor);

    function create(
        ISuperToken superToken,
        bytes32 merkleRoot,
        address treasury,
        IVestingSchedulerV2 vestingScheduler
    )
        external
        returns (MerkleDistributor distributor)
    {
        distributor = new MerkleDistributor(address(superToken), merkleRoot, treasury, vestingScheduler);
        emit Created(distributor);
    }
}   