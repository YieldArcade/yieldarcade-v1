// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface ILRTOracle {
    function rsETHPrice() external view returns (uint256);
}
