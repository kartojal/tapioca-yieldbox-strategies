// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";

interface IStakedUSDeStrategyEventsAndErrors {
    enum PauseType {
        Deposit,
        Withdraw
    }
}

interface IStakedUSDeStrategy is IStakedUSDeStrategyEventsAndErrors {
    // ************** //
    // *** EVENTS *** //
    // ************** //
    event DepositThreshold(uint256 indexed _old, uint256 indexed _new);
    event AmountQueued(uint256 indexed amount);
    event AmountDeposited(uint256 indexed amount);
    event AmountWithdrawn(address indexed to, uint256 indexed amount);
    event ClusterUpdated(ICluster indexed oldCluster, ICluster indexed newCluster);
    event Paused(bool indexed prev, bool indexed crt, bool isDepositType);

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error TokenNotValid();
    error TransferFailed();
    error DepositPaused();
    error WithdrawPaused();
    error NotEnough();
    error PauserNotAuthorized();
    error EmptyAddress();
    error CooldownNotAuthorized();
}
