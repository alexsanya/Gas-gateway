// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../src/PriceOracle.sol";

interface IChainlinkPriceFeed {
  function getEthPriceInUsd() external view returns (uint256);
}

contract PriceOracleTest is Test {
    PriceOracle priceOracle;
    IChainlinkPriceFeed chainlinkPriceFeed;

    function setUp() public {
      priceOracle = new PriceOracle();

      bytes memory bytecode = abi.encodePacked(vm.getCode("ChainlinkPriceFeed.sol"));
      address deployed;
      assembly {
        deployed := create(0, add(bytecode, 0x20), mload(bytecode))
      }
      chainlinkPriceFeed = IChainlinkPriceFeed(deployed);
    }

    function testGetPrice() public {
      console.logString("testGetPrice");
      uint256 weiAmount = priceOracle.getPriceInEth(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 100000000, 180);

      uint256 ethPrice = chainlinkPriceFeed.getEthPriceInUsd();

      console2.log("Ethereum price is: %s", ethPrice);
      console2.log("weiAmount: %s", weiAmount);
      console2.log("equal price: %s", weiAmount * ethPrice / 10**18);
    }


}

