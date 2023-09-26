// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";

import "solmate/tokens/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC2612.sol";

import './SigUtils.sol';
import '../src/GasGateway.sol';
import '../src/GasStation.sol';
import '../src/Interfaces.sol';

contract IntegrationTest is Test {
  using Address for address payable;

  uint256 constant DEPOSIT_VALUE = 1 ether;
  uint256 constant GAS_STATION_ETH_BALANCE = 10 ether;
  ERC20 constant usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant USDC_WHALE = address(0xDa9CE944a37d218c3302F6B82a094844C6ECEb17);
  address constant PRICE_ORACLE = address(0x2);
  uint256 WALLET_PRIVATE_KEY = 0xA11CE;
  address wallet;
  IPriceOracle priceOracle;
  SigUtils sigUtils;
  GasGateway gasGateway;
  GasStation gasStation;

  function setUp() public {
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


    sigUtils = new SigUtils(usdc.DOMAIN_SEPARATOR());
    wallet = vm.addr(WALLET_PRIVATE_KEY);
  }

  function test_shouldExchangeUsdcToEth() public {
    vm.prank(USDC_WHALE);
    usdc.transfer(wallet, 150e6);
    SigUtils.Permit memory permit = SigUtils.Permit({
        owner: wallet,
        spender: address(gasGateway),
        value: 100e6,
        nonce: 0,
        deadline: block.timestamp + 1 days
    });

    bytes32 digest = sigUtils.getTypedDataHash(permit);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(WALLET_PRIVATE_KEY, digest);

    uint256 gasStationEthBalanceBefore = address(gasStation).balance;
    gasStation.exchange(wallet, IERC2612(address(usdc)), 100e6, block.timestamp + 1 days, v, r, s);

    assertEq(usdc.balanceOf(wallet), 50e6);
    assertEq(usdc.balanceOf(address(gasStation)), 100e6);
    assertEq(wallet.balance, gasStationEthBalanceBefore - address(gasStation).balance);

  }
}
