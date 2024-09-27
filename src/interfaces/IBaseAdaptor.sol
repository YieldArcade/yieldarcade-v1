// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { ERC20 } from "@solmate/tokens/ERC20.sol";

interface IBaseAdaptor {
    function deposit(uint256 amount, bytes memory adaptorData) external;

    function withdraw(uint256 amount, address receiver, bytes memory adaptorData) external;

    function assetOf(bytes memory adaptorData) external view returns (ERC20);
}
