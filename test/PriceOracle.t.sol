// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../src/PriceOracle.sol";

contract PriceOracleTest is Test {
    PriceOracle public priceOracle;

    function setUp() public {
      priceOracle = new PriceOracle();
    }

    function testGetPrice() public view {
      console.logString("testGetPrice");
      uint256 weiAmount = priceOracle.getPriceInEth(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 100000000, 180);
      console2.log("weiAmount: %s", weiAmount);
      console2.log("equal price: %s", weiAmount * 161547 / 10**20);
    }
}

