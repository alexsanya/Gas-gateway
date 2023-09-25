// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";

import "solmate/tokens/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import '../src/GasGateway.sol';
import '../src/GasStation.sol';
import '../src/Interfaces.sol';

contract IntegrationTest is Test {
  using Address for address payable;

  uint256 constant DEPOSIT_VALUE = 1 ether;
  uint256 constant GAS_STATION_ETH_BALANCE = 10 ether;
  IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant WALLET = address(0x1);
  address constant PRICE_ORACLE = address(0x2);
  IPriceOracle priceOracle;


  //PriceOracle priceOracle;
  GasGateway gasGateway;
  GasStation gasStation;

  function setUp() public {

    // Deploy
    bytes memory bytecode = abi.encodePacked(vm.getCode("PriceOracle.sol"));
    address deployed;
    assembly {
        deployed := create(0, add(bytecode, 0x20), mload(bytecode))
    }
    priceOracle = IPriceOracle(deployed);

    gasGateway = new GasGateway(priceOracle, DEPOSIT_VALUE);

    address[] memory tokens = new address[](1);
    tokens[0] = address(usdc);
    gasStation = new GasStation{value: GAS_STATION_ETH_BALANCE}(tokens, 500, 180, "apiRoot");
    gasStation.register{value: DEPOSIT_VALUE}(gasGateway);

    payable(WALLET).sendValue(2 ether);
  }

  function test_shouldExchangeUsdcToEth() public {
    //gasStation.exchange();
  }
}
