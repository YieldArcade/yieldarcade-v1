// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface ILRTDepositPool {
    function depositAsset(
        address asset,
        uint256 depositAmount,
        uint256 minRSETHAmountToReceive,
        string calldata referralId
    )
        external;

    function depositETH(uint256 minRSETHAmountExpected, string calldata referralId) external payable;
}
