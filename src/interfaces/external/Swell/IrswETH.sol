// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IrswETH {
    function deposit() external payable;
    function rswETHToETHRate() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}
