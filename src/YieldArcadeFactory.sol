// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract YieldArcadeFactory {
    uint256 public constant BASIS_POINTS_DIVISOR = 10_000; // 100 basis points

    struct StrategyState {
        uint8 protocolIds;
        uint8 depositPercent;
    }

    mapping(address => StrategyState) public strategies;

    constructor() { }

    function createStrategy(uint8[] calldata protocols, uint8[] calldata percentage) external returns (address) { }
}
