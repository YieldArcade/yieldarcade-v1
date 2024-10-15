// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface IPufferVaultV3 {
    function depositETH(address receiver) external payable returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
}
