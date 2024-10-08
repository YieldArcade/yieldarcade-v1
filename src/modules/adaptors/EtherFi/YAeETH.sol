// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { ILiquidityPool } from "../../../interfaces/external/EtherFi/ILiquidityPool.sol";
import { ILiquifier } from "../../../interfaces/external/EtherFi/ILiquifier.sol";
import { TransferHelper } from "../../../libraries/TransferHelper.sol";

import { BaseAdaptor } from "../BaseAdaptor.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";

contract YAeETH is BaseAdaptor {
    ERC20 public immutable eETH;
    address public immutable yAStrategy;
    ILiquifier public immutable liquifier;
    ILiquidityPool public immutable liquidityPool;

    constructor(ILiquidityPool _liquidityPool, ILiquifier _liquifier, ERC20 _eETH, address _yAStrategy) {
        eETH = _eETH;
        liquifier = _liquifier;
        yAStrategy = _yAStrategy;
        liquidityPool = _liquidityPool;
    }

    function deposit(address tokenIn, uint256 amount, bytes memory adaptorData) external override {
        if (tokenIn == NATIVE) {
            liquidityPool.deposit{ value: amount }();
        } else {
            TransferHelper.safeApprove(tokenIn, address(liquifier), amount);
            liquifier.depositWithERC20(tokenIn, amount, address(0));
        }

        TransferHelper.safeTransfer(address(eETH), yAStrategy, eETH.balanceOf(address(this)));
    }

    function withdraw(address receiver, uint256 amount, bytes memory adaptorData) external override {
        liquidityPool.withdraw(receiver, amount);
    }

    function assetInfo(bytes memory adaptorData) external view override returns (ERC20, uint8) {
        return (eETH, 18);
    }

    function exchangeRate(uint256 amount) external view override returns (uint256) {
        return liquidityPool.sharesForAmount(amount);
    }
}
