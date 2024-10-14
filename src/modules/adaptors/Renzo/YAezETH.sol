// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { IRestakeManager } from "../../../interfaces/external/Renzo/IRestakeManager.sol";
import { IRateProvider } from "../../../interfaces/external/Renzo/IRateProvider.sol";

import { TransferHelper } from "../../../libraries/TransferHelper.sol";

import { BaseAdaptor } from "../BaseAdaptor.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { FixedPointMathLib } from "@solmate/utils/FixedPointMathLib.sol";

contract YAezETH is BaseAdaptor {
    using FixedPointMathLib for uint256;

    ERC20 public immutable ezETH;

    address public exchangeRateOracle;
    address public immutable renzoOracle;
    address public immutable yAStrategy;

    uint256 public immutable referralId;
    IRestakeManager public immutable restakeManager;

    constructor(
        address _ezETH,
        address _yAStrategy,
        address _stakeManager,
        address _exchangeRateOracle,
        uint256 _referralId
    ) {
        ezETH = ERC20(_ezETH);
        yAStrategy = _yAStrategy;
        restakeManager = IRestakeManager(_stakeManager);
        exchangeRateOracle = _exchangeRateOracle;
        renzoOracle = restakeManager.renzoOracle();
        referralId = _referralId;
    }

    function deposit(bytes memory adaptorData) external payable override {
        restakeManager.depositETH{ value: msg.value }(referralId);
        TransferHelper.safeTransfer(address(ezETH), yAStrategy, ezETH.balanceOf(address(this)));
    }

    function assetInfo(bytes memory adaptorData) external view override returns (ERC20, uint8) {
        return (ezETH, 18);
    }

    function exchangeRate(uint256 share) external view override returns (uint256) {
        return share.mulWadUp(IRateProvider(exchangeRateOracle).getRate());
    }
}
