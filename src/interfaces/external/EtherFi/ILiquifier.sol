// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface ILiquifier {
    function depositWithERC20(address _token, uint256 _amount, address _referral) external returns (uint256);
}
