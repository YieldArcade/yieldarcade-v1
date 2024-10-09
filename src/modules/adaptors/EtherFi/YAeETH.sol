// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { ILiquidityPool } from "../../../interfaces/external/EtherFi/ILiquidityPool.sol";
import { TransferHelper } from "../../../libraries/TransferHelper.sol";

import { BaseAdaptor } from "../BaseAdaptor.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";

contract YAeETH is BaseAdaptor {
    ERC20 public immutable eETH;
    address public immutable yAStrategy;
    ILiquidityPool public immutable liquidityPool;

    constructor(ILiquidityPool _liquidityPool, address _eETH, address _yAStrategy) {
        eETH = ERC20(_eETH);
        yAStrategy = _yAStrategy;
        liquidityPool = _liquidityPool;
    }

    function deposit(uint256 amount, bytes memory adaptorData) external override {
        liquidityPool.deposit{ value: amount }();
        TransferHelper.safeTransfer(address(eETH), yAStrategy, eETH.balanceOf(address(this)));
    }

    function assetInfo(bytes memory adaptorData) external view override returns (ERC20, uint8) {
        return (eETH, 18);
    }

    function exchangeRate(uint256 amount) external view override returns (uint256) {
        return liquidityPool.sharesForAmount(amount);
    }
}
