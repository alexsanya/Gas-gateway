// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/GasStation.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract GasStationTest is Test {
  IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address[] tokens;
  
  constructor() {
    tokens.push(address(usdc));
  }

  function setUp() public {
  }

  function test_RevertIfComissionExceeds100percent() public {
    vm.expectRevert("Comission cannot exceed 100%");
    GasStation gasStation = new GasStation(tokens, 10001, 180, "api");
  }

  function test_RevertIfTokensListIsEmpty() public {
    vm.expectRevert("Should support at least 1 token");
    GasStation gasStation = new GasStation(new address[](0), 500, 180, "api");
  }

  function test_CreateGasStationAndSetUpParameters() public {
    GasStation gasStation = new GasStation(tokens, 500, 180, "api");
    assertEq(gasStation.comission(), 500);
    assertEq(gasStation.twapPeriod(), 180);
    assertEq(gasStation.apiRoot(), "api");
    assertEq(gasStation.getTokens(), tokens);
  }
}
