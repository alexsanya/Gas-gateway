// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";

//import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "solmate/src/tokens/ERC20.sol";

import '../src/PriceOracle.sol';
import '../src/GasGateway.sol';
import '../src/GasStation.sol';

contract IntegrationTest is Test {
  uint256 constant DEPOSIT_VALUE = 1 ether;
  uint256 constant GAS_STATION_ETH_BALANCE = 10 ether;
  IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant WALLET = address(0x1);


  PriceOracle priceOracle;
  GasGateway gasGateway;
  GasStation gasStation;

  function setUp() {
    priceOracle = new PriceOracle();
    gasGateway = new GasGateway(priceOracle, DEPOSIT_VALUE);

    address[] memory tokens = new address[](1);
    tokens[0] = address(usdc);
    gasStation = new GasStation{value: GAS_STATION_ETH_BALANCE}(tokens, 500, 180, "apiRoot");
    gasStation.register{value: DEPOSIT_VALUE}(gasGateway);

    payable(wallet).sendValue(2 ether);
  }

  function shouldExchangeUsdcToEth() public {
    gasStation.exchange();
  }
}
