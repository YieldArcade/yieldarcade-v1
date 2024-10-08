// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { FullMath } from "./libraries/FullMath.sol";
import { TransferHelper } from "./libraries/TransferHelper.sol";
import { ReentrancyGuard } from "@solmate/utils/ReentrancyGuard.sol";

import { IBaseAdaptor } from "./interfaces/IBaseAdaptor.sol";

import { Registry } from "./Registry.sol";
import { PriceRouter } from "./modules/PriceRouter.sol";

/// @title Yield Arcade Vault
/// @notice A composable ERC20 that can use arbitrary DeFi LRT platforms using adaptors.
/// @author 0xMudassir
contract YieldArcadeRestakingStrategy is ERC20 {
    uint256 private locked = 1;

    address internal constant NATIVE = address(0);

    uint256 internal constant MIN_INITIAL_SHARES = 1e9;

    uint256 internal constant BASIS_POINTS_DIVISOR = 10_000;

    /// @notice Address of the platform's registry contract. Used to get the latest address of modules.
    Registry public immutable registry;

    /// @notice Array of uint16s made up of restaking platforms Ids.
    uint16[] internal protocolIds;

    /// @notice Array of uint16s made up of percentage allocated to each restaking platform Id.
    uint16[] internal protocolPercentage;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }

    constructor(
        Registry _registry,
        uint16[] memory _protocolIds,
        uint16[] memory _protocolPercentage,
        string memory _name,
        string memory _symbol
    )
        ERC20(_name, _symbol, 18)
    {
        if (_protocolIds.length != _protocolPercentage.length) revert();
        if (address(_registry) == address(0)) revert();

        registry = _registry;

        address adaptor;
        uint16 totalPercentage;

        for (uint256 i = 0; i < _protocolIds.length; i++) {
            adaptor = registry.getAddress(_protocolIds[i]);
            // Make sure adaptor is trusted.
            registry.revertIfAdaptorIsNotTrusted(adaptor);

            totalPercentage += _protocolPercentage[i];
        }

        // Make sure accumulated percentage should be 100% of amount
        if (totalPercentage != BASIS_POINTS_DIVISOR) revert();

        protocolIds = _protocolIds;
        protocolPercentage = _protocolPercentage;
    }

    /// @notice Deposits assets into the vault, and returns shares to receiver.
    /// @param amount amount of assets deposited by user.
    /// @param receiver address to receive the shares.
    /// @return shares amount of shares given for deposit.
    function deposit(
        address depositAsset,
        uint256 amount,
        address receiver
    )
        external
        payable
        returns (uint256 shares)
    {
        // calculate shares here
        shares = _calculateShares(depositAsset, amount);

        // deposit in platforms acc to strategy
        _depositTo(depositAsset, amount);

        // mint shares w.r.t conversion rate of protocols
        _mint(receiver, shares);
    }

    /// @dev Deposit into a protocol according to its ratio type and update related state.
    function _depositTo(address depositAsset, uint256 amount) internal {
        uint256 allocation;
        uint256 remainingAmount = amount;
        uint256 length = protocolIds.length;

        for (uint256 i = 0; i < length - 1; i++) {
            allocation = FullMath.mulDiv(amount, protocolPercentage[i], BASIS_POINTS_DIVISOR);

            _makeDepositCall(depositAsset, registry.getAddress(protocolIds[i]), allocation, "");

            // make sure protocol recipt has been recieved in correct amount

            // deduct the deposited amount
            remainingAmount -= allocation;
        }

        // deposit remining in last to avoid rounding errors:
        _makeDepositCall(depositAsset, registry.getAddress(protocolIds.length - 1), remainingAmount, "");
    }

    /// @notice Internal helper function that accepts an Adaptor Call array, and makes calls to each adaptor.
    function _makeDepositCall(address depositAsset, address adaptor, uint256 amount, bytes memory data) internal {
        // Make sure adaptor is trusted.
        registry.revertIfAdaptorIsNotTrusted(adaptor);

        if (depositAsset == NATIVE) {
            IBaseAdaptor(adaptor).deposit{ value: amount }(depositAsset, amount, data);
        } else {
            TransferHelper.safeTransferFrom(depositAsset, msg.sender, adaptor, amount);

            IBaseAdaptor(adaptor).deposit(depositAsset, amount, data);
        }
    }

    function withdraw(uint256 shares, address recipient) external { }

    function _mintShares(uint256 _totalDeposited, uint256 _amountDeposited) internal view returns (uint256 shares) {
        uint256 _existingShareSupply = totalSupply;

        if (_existingShareSupply == 0) {
            // no existing shares, bootstrap at rate 1:1
            shares = _amountDeposited;

            require(shares > MIN_INITIAL_SHARES, "M");
        } else {
            // shares = existingShareSupply * amountDeposited / totalDeposited;
            shares = FullMath.mulDiv(_existingShareSupply, _amountDeposited, _totalDeposited);

            require(shares != 0, "0");
        }
    }

    function _getEthReserves(address _adaptor) internal view returns (uint256) {
        IBaseAdaptor adaptor = IBaseAdaptor(_adaptor);

        return adaptor.exchangeRate(adaptor.assetInfo("").balanceOf(address(this)));
    }

    function _calculateShares(address _tokenIn, uint256 _amountDeposited) internal view returns (uint256 shares) {
        address adaptor;
        uint256 totalEth;
        uint256 length = protocolIds.length;

        for (uint256 i = 0; i < length; i++) {
            adaptor = registry.getAddress(protocolIds[i]);

            registry.revertIfAdaptorIsNotTrusted(adaptor);

            totalEth += _getEthReserves(adaptor);
        }

        if (_tokenIn == NATIVE) {
            shares = _mintShares(totalEth, _amountDeposited);
        } else {
            shares = 0;
        }
    }
}
