// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { IrswETH } from "../../../interfaces/external/Swell/IrswETH.sol";

import { TransferHelper } from "../../../libraries/TransferHelper.sol";

import { BaseAdaptor } from "../BaseAdaptor.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { FixedPointMathLib } from "@solmate/utils/FixedPointMathLib.sol";

contract YArswETH is BaseAdaptor {
    using FixedPointMathLib for uint256;

    address public immutable rswETH;
    address public immutable yAStrategy;

    constructor(address _rswETH, address _yAStrategy) {
        rswETH = _rswETH;
        yAStrategy = _yAStrategy;
    }

    function deposit(bytes memory adaptorData) external payable override {
        IrswETH rsETHDeposit = IrswETH(rswETH);

        rsETHDeposit.deposit{ value: msg.value }();
        TransferHelper.safeTransfer(rswETH, yAStrategy, rsETHDeposit.balanceOf(address(this)));
    }

    function assetInfo(bytes memory adaptorData) external view override returns (ERC20, uint8) {
        return (ERC20(rswETH), 18);
    }

    function exchangeRate(uint256 share) external view override returns (uint256) {
        return share.mulWadUp(IrswETH(rswETH).rswETHToETHRate());
    }
}
