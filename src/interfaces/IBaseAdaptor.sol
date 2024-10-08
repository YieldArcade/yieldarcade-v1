// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { ERC20 } from "@solmate/tokens/ERC20.sol";

interface IBaseAdaptor {
    function deposit(address depositAsset, uint256 amount, bytes memory adaptorData) external payable;

    function withdraw(uint256 amount, address receiver, bytes memory adaptorData) external;

    function assetInfo(bytes memory adaptorData) external view returns (ERC20);

    function exchangeRate(uint256 amount) external view returns (uint256);
}
