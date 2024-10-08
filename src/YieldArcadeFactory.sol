// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import { Registry } from "./Registry.sol";
import { YieldArcadeVault } from "./YieldArcadeVault.sol";

contract YieldArcadeFactory {
    error Factory__InvalidPercentageComposition();

    error Factory__InvalidArrayLength();

    /// @notice Address of the platform's registry contract.
    Registry public immutable registry;

    uint256 public constant BASIS_POINTS_DIVISOR = 10_000; // 100 basis points (100%)

    struct StrategyState {
        uint16[] protocolIds;
        uint16[] depositPercent;
    }

    struct StrategyStateId {
        uint16 stakingProtocolId;
        uint16 depositPercentage;
        uint16[] restakingProtocolIds;
        uint16[] restakingDepositPercentage;
    }

    mapping(address => StrategyStateId[]) internal strategies;

    // mapping(address => StrategyStateId[]) internal strategy;

    constructor(Registry _registry) {
        registry = _registry;
    }

    function createStrategy(
        uint16[] calldata protocols,
        uint16[] calldata percentages,
        StrategyStateId[] calldata ids
    )
        external
        returns (address vault)
    {
        if (protocols.length != percentages.length) revert Factory__InvalidArrayLength();

        uint16 i;
        address adaptor;
        uint16 stakingPercentage;
        uint16 restakingPercentage;

        for (i = 0; i < ids.length; i++) {
            if (ids[i].stakingProtocolId != 0) {
                // Make sure staking adaptor is trusted.
                adaptor = registry.getAddress(ids[i].stakingProtocolId);
                registry.revertIfAdaptorIsNotTrusted(adaptor);

                stakingPercentage += ids[i].depositPercentage;
            }

            for (uint256 j = 0; j < ids[i].restakingProtocolIds.length; j++) {
                // Make sure restaking adaptor is trusted.
                adaptor = registry.getAddress(ids[i].restakingProtocolIds[j]);
                registry.revertIfAdaptorIsNotTrusted(adaptor);

                restakingPercentage += ids[i].restakingDepositPercentage[j];
            }

            if (restakingPercentage > 0) {
                if (restakingPercentage != BASIS_POINTS_DIVISOR) revert Factory__InvalidPercentageComposition();
            }
        }

        // Make sure accumulated percentage should be 100% of amount
        if (stakingPercentage > 0) {
            if (stakingPercentage != BASIS_POINTS_DIVISOR) revert Factory__InvalidPercentageComposition();
        }

        vault = address(new YieldArcadeVault{ salt: keccak256(abi.encodePacked("d")) }(registry, "YAV", "Vault", 18));

        // strategies[vault] = ids;
    }

    function getVaultComposition(address vault) external view returns (StrategyState memory) {
        // return strategies[vault];
    }
}
