// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { IPufferVaultV3 } from "../../../interfaces/external/Puffer/IPufferVaultV3.sol";

import { BaseAdaptor } from "../BaseAdaptor.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";

contract YApufETH is BaseAdaptor {
    address public immutable pufETH;
    address public immutable yAStrategy;

    constructor(address _pufETH, address _yAStrategy) {
        pufETH = _pufETH;
        yAStrategy = _yAStrategy;
    }

    function deposit(bytes memory adaptorData) external payable override {
        IPufferVaultV3(pufETH).depositETH{ value: msg.value }(yAStrategy);
    }

    function exchangeRate(uint256 share) external view override returns (uint256) {
        return IPufferVaultV3(pufETH).convertToAssets(share);
    }

    function assetInfo(bytes memory adaptorData) external view override returns (ERC20, uint8) {
        return (ERC20(pufETH), 18);
    }
}
