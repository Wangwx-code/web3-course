// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title DataFeed
 * @dev 一个用于获取 Chainlink 价格数据并进行货币转换的合约
 */
contract DataFeed {
    AggregatorV3Interface internal immutable _LINK_USD_FEED;
    AggregatorV3Interface internal immutable _ETH_USD_FEED;
    uint256 private constant STALE_THRESHOLD = 1 hours;

    // 错误定义
    error InvalidPriceFeed(address feed);
    error StalePriceFeed(address feed, uint256 updatedAt);
    error InvalidPrice(int256 price);
    error InvalidAmount(uint256 amount);
    error CalculationOverflow();

    /**
     * @dev 构造函数，初始化价格喂价合约
     * @param ethUsdFeed ETH/USD 价格喂价地址
     * @param linkUsdFeed LINK/USD 价格喂价地址
     */
    constructor(address ethUsdFeed, address linkUsdFeed) {
        if (linkUsdFeed == address(0)) {
            revert InvalidPriceFeed(linkUsdFeed);
        }
        if (ethUsdFeed == address(0)) {
            revert InvalidPriceFeed(ethUsdFeed);
        }

        _LINK_USD_FEED = AggregatorV3Interface(linkUsdFeed);
        _ETH_USD_FEED = AggregatorV3Interface(ethUsdFeed);
    }

    /**
     * @dev 获取价格喂价的最新数据
     * @param dataFeed 价格喂价合约接口
     * @return price 最新价格
     * @return updatedAt 更新时间戳
     */
    function getChainlinkDataFeedLatestData(
        AggregatorV3Interface dataFeed
    ) public view returns (int256 price, uint256 updatedAt) {
        (
            uint80 roundId,
            int256 answer, // startedAt - 未使用
            ,
            uint256 timestamp,
            uint80 answeredInRound
        ) = dataFeed.latestRoundData();

        // 检查价格有效性
        if (answer <= 0) {
            revert InvalidPrice(answer);
        }

        // 检查数据是否过时
        if (timestamp + STALE_THRESHOLD < block.timestamp) {
            revert StalePriceFeed(address(dataFeed), timestamp);
        }

        // 检查数据是否是最新的
        if (answeredInRound < roundId) {
            revert StalePriceFeed(address(dataFeed), timestamp);
        }

        return (answer, timestamp);
    }

    /**
     * @dev 获取 LINK/USD 最新价格
     */
    function getLatestLinkPrice() external view returns (int256) {
        (int256 price, ) = getChainlinkDataFeedLatestData(_LINK_USD_FEED);
        return price;
    }

    /**
     * @dev 获取 ETH/USD 最新价格
     */
    function getLatestEthPrice() external view returns (int256) {
        (int256 price, ) = getChainlinkDataFeedLatestData(_ETH_USD_FEED);
        return price;
    }

    /**
     * @dev 将 ETH 数量转换为 USD 价值
     * @param ethAmount ETH 数量（以 wei 为单位）
     * @return usdValue USD 价值（以 8 位小数表示）
     */
    function convertEthToUSD(
        uint256 ethAmount
    ) internal view returns (uint256) {
        if (ethAmount == 0) {
            revert InvalidAmount(ethAmount);
        }

        (int256 ethPrice, ) = getChainlinkDataFeedLatestData(_ETH_USD_FEED);
        uint8 decimals = _ETH_USD_FEED.decimals();

        uint256 divisor = 10 ** (18 + decimals - 8);
        return _safeMulDiv(ethAmount, uint256(ethPrice), divisor);
    }

    /**
     * @dev 将 LINK 数量转换为 USD 价值
     * @param linkAmount LINK 数量（以 wei 为单位）
     * @return usdValue USD 价值（以 8 位小数表示）
     */
    function convertLinkToUSD(
        uint256 linkAmount
    ) internal view returns (uint256) {
        if (linkAmount == 0) {
            revert InvalidAmount(linkAmount);
        }

        (int256 linkPrice, ) = getChainlinkDataFeedLatestData(_LINK_USD_FEED);
        uint8 decimals = _LINK_USD_FEED.decimals();

        uint256 divisor = 10 ** (18 + decimals - 8);
        return _safeMulDiv(linkAmount, uint256(linkPrice), divisor);
    }

    /**
     * @dev 安全的乘法后除法操作，避免溢出
     */
    function _safeMulDiv(
        uint256 a,
        uint256 b,
        uint256 divisor
    ) private pure returns (uint256) {
        if (divisor == 0) {
            revert InvalidAmount(divisor);
        }

        // 检查乘法是否会导致溢出
        if (a > 0 && b > type(uint256).max / a) {
            revert CalculationOverflow();
        }

        uint256 result = (a * b) / divisor;
        return result;
    }

    /**
     * @dev 获取合约中使用的价格喂价地址
     */
    function getFeedAddresses()
        external
        view
        returns (address linkFeed, address ethFeed)
    {
        return (address(_LINK_USD_FEED), address(_ETH_USD_FEED));
    }
}
