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
contract YieldArcadeVault is ERC20 {
    uint256 private locked = 1;

    uint256 public constant BASIS_POINTS_DIVISOR = 10_000;

    struct StrategyStateId {
        uint16 stakingProtocolId;
        uint16 depositPercentage;
        uint16[] restakingProtocolIds;
        uint16[] restakingDepositPercentage;
    }

    /// @notice Array of uint16s made up of staking/restaking platforms Ids & their composition.
    StrategyStateId[] internal vaultStrategy;

    /// @notice Array of uint16s made up of restaking platforms Ids.
    uint16[] internal protocolIds;

    /// @notice Array of uint16s made up of percentage allocated to each restaking platform Id.
    uint16[] internal protocolPercentage;

    /// @notice Address of price router contract.
    PriceRouter public priceRouter;

    /// @notice Address of the platform's registry contract. Used to get the latest address of modules.
    Registry public immutable registry;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }

    constructor(
        Registry _registry,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        ERC20(_name, _symbol, _decimals)
    {
        registry = _registry;
        // vaultStrategy = _strategy;
    }

    /// @notice Deposits assets into the vault, and returns shares to receiver.
    /// @param amount amount of assets deposited by user.
    /// @param receiver address to receive the shares.
    /// @return shares amount of shares given for deposit.
    function deposit(address depositAsset, uint256 amount, address receiver) external returns (uint256 shares) {
        TransferHelper.safeTransferFrom(depositAsset, msg.sender, address(this), amount);

        // calculate shares here

        // deposit in platforms acc to strategy
        _depositTo(amount);

        // mint shares w.r.t conversion rate of protocols
        _mint(receiver, shares);
    }

    function _depositToStaking(ERC20 depositAsset, uint256 amount) internal { }

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

    function withdraw() external returns (uint256 shares) { }

    /// @notice Struct used to make calls to adaptors.
    /// @param adaptor the address of the adaptor to make calls to
    /// @param the abi encoded function calls to make to the `adaptor`
    struct AdaptorCall {
        address adaptor;
        bytes[] callData;
    }

    /// @notice Internal helper function that accepts an Adaptor Call array, and makes calls to each adaptor.
    function _makeDepositCall(address adaptor, uint256 amount, bytes memory data) internal {
        // Make sure adaptor is trusted.
        registry.revertIfAdaptorIsNotTrusted(adaptor);

        IBaseAdaptor(adaptor).deposit(address(0), amount, data);
    }

    function _makeWithdrawCall(address adaptor, uint256 amount, address receiver, bytes memory data) internal {
        // Make sure adaptor is trusted.
        registry.revertIfAdaptorIsNotTrusted(adaptor);

        IBaseAdaptor(adaptor).withdraw(amount, receiver, data);
    }
}
