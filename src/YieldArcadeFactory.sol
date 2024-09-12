// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { Registry } from "./Registry.sol";
import { YieldArcadeVault } from "./YieldArcadeVault.sol";

contract YieldArcadeFactory {
    /// @notice Address of the platform's registry contract.
    Registry public immutable registry;

    uint256 public constant BASIS_POINTS_DIVISOR = 10_000; // 100 basis points (100%)

    struct StrategyState {
        uint16[] protocolIds;
        uint16[] depositPercent;
    }

    mapping(address => StrategyState) internal strategies;

    constructor(Registry _registry) {
        registry = _registry;
    }

    function createStrategy(
        uint16[] calldata protocols,
        uint16[] calldata percentages
    )
        external
        returns (address vault)
    {
        if (protocols.length != percentages.length) revert();

        uint16 i;
        uint16 totalPercentage;

        for (i = 0; i < protocols.length; i++) {
            address adaptor = registry.getAddress(protocols[i]);
            // Make sure adaptor is trusted.
            registry.revertIfAdaptorIsNotTrusted(adaptor);
        }

        for (i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }

        // Make sure accumulated percentage should be 100% of amount
        if (totalPercentage != BASIS_POINTS_DIVISOR) revert();

        vault = address(
            new YieldArcadeVault{ salt: keccak256(abi.encodePacked("d")) }(
                registry, protocols, percentages, "YAV", "Vault", 18
            )
        );

        strategies[vault] = StrategyState({ protocolIds: protocols, depositPercent: percentages });
    }

    function getVaultComposition(address vault) external view returns (StrategyState memory) {
        return strategies[vault];
    }
}
