// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

interface ITUSDe {
    function wrap(
        address _fromAddress,
        address _toAddress,
        uint256 _amount
    ) external payable;

    function unwrap(address _toAddress, uint256 _amount) external;

    function erc20() external view returns (address);
}
