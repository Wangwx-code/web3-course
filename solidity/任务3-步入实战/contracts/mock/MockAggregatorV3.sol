// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MockAggregatorV3 (简化版)
 * @dev 最小化的 Chainlink AggregatorV3Interface 模拟
 */
contract MockAggregatorV3 {
    uint8 private _decimals;
    int256 private _price;
    uint80 private _roundId = 1;
    
    constructor(uint8 decimals_, int256 price_) {
        _decimals = decimals_;
        _price = price_;
    }
    
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            _roundId,
            _price,
            block.timestamp - 1 hours,
            block.timestamp,
            _roundId
        );
    }
    
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    
    function description() external pure returns (string memory) {
        return "Mock Aggregator V3";
    }
    
    function version() external pure returns (uint256) {
        return 1;
    }
    
    function updatePrice(int256 newPrice) external {
        _price = newPrice;
        _roundId++;
    }
    
    function getPrice() external view returns (int256) {
        return _price;
    }
}