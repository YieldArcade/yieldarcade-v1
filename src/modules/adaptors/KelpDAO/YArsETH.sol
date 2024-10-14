// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { ILRTDepositPool } from "../../../interfaces/external/KelpDAO/ILRTDepositPool.sol";
import { ILRTOracle } from "../../../interfaces/external/KelpDAO/ILRTOracle.sol";

import { TransferHelper } from "../../../libraries/TransferHelper.sol";

import { BaseAdaptor } from "../BaseAdaptor.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { FixedPointMathLib } from "@solmate/utils/FixedPointMathLib.sol";

contract YAezETH is BaseAdaptor {
    using FixedPointMathLib for uint256;

    /// @notice LRT deposit pool deposits are made to.
    ILRTDepositPool public immutable lrtDepositPool;

    /// @notice LRT Oracle to fetch the rsETH price.
    ILRTOracle public immutable lrtOracle;

    /// @notice Token returned from deposits.
    ERC20 public immutable rsETH;

    /// @notice The address of yield arcade strategy
    address public immutable yAStrategy;

    constructor(address _lrtDepositPool, address _lrtOracle, address _rsETH, address _yAStrategy) {
        lrtDepositPool = ILRTDepositPool(_lrtDepositPool);
        lrtOracle = ILRTOracle(_lrtOracle);
        rsETH = ERC20(_rsETH);
        yAStrategy = _yAStrategy;
    }

    function deposit(bytes memory adaptorData) external payable override {
        lrtDepositPool.depositETH{ value: msg.value }(0, "");
        TransferHelper.safeTransfer(address(rsETH), yAStrategy, rsETH.balanceOf(address(this)));
    }

    function assetInfo(bytes memory adaptorData) external view override returns (ERC20, uint8) {
        return (rsETH, 18);
    }

    function exchangeRate(uint256 share) external view override returns (uint256) {
        return share.mulWadUp(lrtOracle.rsETHPrice());
    }
}
