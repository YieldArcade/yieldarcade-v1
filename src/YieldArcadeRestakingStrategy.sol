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
    /// @param receiver address to receive the shares.
    /// @return shares amount of shares given for deposit.
    function deposit(address receiver) external payable returns (uint256 shares) {
        // calculate shares here
        shares = _calculateShares(msg.value);

        // deposit in platforms acc to strategy
        _depositTo(msg.value);

        // mint shares w.r.t conversion rate of protocols
        _mint(receiver, shares);
    }

    /// @dev Deposit into a protocol according to its ratio type and update related state.
    function _depositTo(uint256 amount) internal {
        uint256 allocation;
        uint256 remainingAmount = amount;
        uint256 length = protocolIds.length;

        for (uint256 i = 0; i < length - 1; i++) {
            allocation = FullMath.mulDiv(amount, protocolPercentage[i], BASIS_POINTS_DIVISOR);

            _makeDepositCall(registry.getAddress(protocolIds[i]), allocation, "");

            // make sure protocol recipt has been recieved in correct amount

            // deduct the deposited amount
            remainingAmount -= allocation;
        }

        // deposit remining in last to avoid rounding errors:
        _makeDepositCall(registry.getAddress(protocolIds.length - 1), remainingAmount, "");
    }

    /// @notice Internal helper function that accepts an Adaptor Call, and makes calls to each adaptor.
    function _makeDepositCall(address adaptor, uint256 amount, bytes memory data) internal {
        // Make sure adaptor is trusted.
        registry.revertIfAdaptorIsNotTrusted(adaptor);

        IBaseAdaptor(adaptor).deposit{ value: amount }(data);
    }

    function withdraw(uint256 shares, address recipient) external {
        if (shares == 0) revert();

        address adaptor;
        uint256 userTokenShare;
        uint256 length = protocolIds.length;

        uint256 liquidityShare = FullMath.mulDiv(shares, 1e18, totalSupply);

        for (uint256 i = 0; i < length; i++) {
            adaptor = registry.getAddress(protocolIds[i]);

            registry.revertIfAdaptorIsNotTrusted(adaptor);

            // reuse adaptor & userTokenShare vars for asset info(tokenAddress, tokenBalanceOfVault)
            (adaptor, userTokenShare) = _fetchAssetDetails(adaptor);

            // calulcate LRT token share for user
            userTokenShare = FullMath.mulDiv(userTokenShare, liquidityShare, 1e18);

            // transfer each LRT share
            TransferHelper.safeTransfer(adaptor, recipient, userTokenShare);
        }

        _burn(msg.sender, shares);
    }

    function _getEthReserves(address _adaptor) internal view returns (uint256) {
        (, uint256 balance) = _fetchAssetDetails(_adaptor);

        return IBaseAdaptor(_adaptor).exchangeRate(balance);
    }

    function _fetchAssetDetails(address _adaptor) internal view returns (address, uint256) {
        IBaseAdaptor adaptor = IBaseAdaptor(_adaptor);

        return (address(adaptor.assetInfo("")), adaptor.assetInfo("").balanceOf(address(this)));
    }

    function _calculateShares(uint256 _amountDeposited) internal view returns (uint256 shares) {
        address _adaptor;
        uint256 _totalEth;
        uint256 _length = protocolIds.length;
        uint256 _existingShareSupply = totalSupply;

        for (uint256 i = 0; i < _length; i++) {
            _adaptor = registry.getAddress(protocolIds[i]);

            registry.revertIfAdaptorIsNotTrusted(_adaptor);

            _totalEth += _getEthReserves(_adaptor);
        }

        if (_existingShareSupply == 0) {
            // no existing shares, bootstrap at rate 1:1
            shares = _amountDeposited;

            require(shares > MIN_INITIAL_SHARES, "M");
        } else {
            // shares = existingShareSupply * amountDeposited / totalDeposited;
            shares = FullMath.mulDiv(_existingShareSupply, _amountDeposited, _totalEth);

            require(shares != 0, "0");
        }
    }
}
