// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { IBaseAdaptor } from "../../interfaces/IBaseAdaptor.sol";
import { SafeTransferLib } from "@solmate/utils/SafeTransferLib.sol";
// import { TransferHelper } from "../../libraries/TransferHelper.sol";

/// @title Base Adaptor
/// @notice Base contract all adaptors must inherit from.
/// @dev Allows vaults to interact with arbritrary DeFi assets and protocols.
/// @author 0xMudassir
abstract contract BaseAdaptor {
    using SafeTransferLib for ERC20;

    /// @notice Function vaults call to deposit users funds into protocol.
    /// @param amount the amount of assets to deposit
    /// @param adaptorData data needed to deposit into a protocol
    function deposit(uint256 amount, bytes memory adaptorData) external virtual;

    // / @notice Function vaults call to withdraw funds from protocol to send to users.
    // / @param receiver the address that should receive withdrawn funds
    // / @param adaptorData data needed to withdraw from a position
    // function withdraw(address receiver, uint256 amount, bytes memory adaptorData) external virtual;

    function assetInfo(bytes memory adaptorData) external view virtual returns (ERC20, uint8);

    function exchangeRate(uint256 amount) external view virtual returns (uint256);

    /// @notice Function vault use to determine the underlying ERC20 asset of a position.
    /// @param adaptorData data needed to withdraw from a position
    /// @return the underlying ERC20 asset of a position
    // function assetOf(bytes memory adaptorData) external view virtual returns (ERC20);

    /// @notice Helper function that checks if `spender` has any more approval for `asset`, and if so revokes it.
    function _revokeExternalApproval(ERC20 asset, address spender) internal {
        if (asset.allowance(address(this), spender) > 0) asset.safeApprove(spender, 0);
    }

    /// @notice Allows to zero out an approval for a given `asset`.
    /// @param asset the ERC20 asset to revoke `spender`s approval for
    /// @param spender the address to revoke approval for
    function revokeApproval(ERC20 asset, address spender) public {
        asset.safeApprove(spender, 0);
    }
}
