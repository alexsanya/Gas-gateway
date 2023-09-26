// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../src/PriceOracle.sol";

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract PriceOracleTest is Test {
    AggregatorV3Interface constant ethPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    PriceOracle public priceOracle;

    function setUp() public {
      priceOracle = new PriceOracle();
    }

    function testGetPrice() public {
      console.logString("testGetPrice");
      uint256 weiAmount = priceOracle.getPriceInEth(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 100000000, 180);

      uint256 ethPrice = chainlinkPrice(ethPriceFeed) / 10**6;

      console2.log("Ethereum price is: %s", ethPrice);
      console2.log("weiAmount: %s", weiAmount);
      console2.log("equal price: %s", weiAmount * ethPrice / 10**18);
    }

    function chainlinkPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

}

