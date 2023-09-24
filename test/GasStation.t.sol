// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/GasStation.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../src/Interfaces.sol";

contract GasStationTest is IGasGateway, Test {
  using Address for address payable;

  IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  uint256 public depositValue = 1 ether;
  address[] tokens;
  
  constructor() {
    tokens.push(address(usdc));
  }

  function setUp() public {
  }

  function register() external payable {

  }

  function deList() external {

  }

  function exchange(address wallet, address token, uint256 amount) external payable {

  }

  function getEthAmount(address, uint256) external view returns (uint256) {

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

  function test_RevertRegisterIfSenderIsNotAnOwner() public {
    GasStation gasStation = new GasStation(tokens, 500, 180, "api");
    payable(address(0x1)).sendValue(2 ether);
    vm.prank(address(0x1));
    vm.expectRevert("Ownable: caller is not the owner");
    gasStation.register{value: depositValue}(IGasGateway(this));
  }

  function test_RevertRegisterIfNotEnoughEthProvided() public {
    GasStation gasStation = new GasStation(tokens, 500, 180, "api");
    vm.expectRevert("Not enough eth for deposit");
    gasStation.register{value: depositValue - 1}(IGasGateway(this));
  }

  function test_RegisterGasStation() public {
    GasStation gasStation = new GasStation(tokens, 500, 180, "api");
    gasStation.register{value: depositValue}(IGasGateway(this));
  }

  function test_RevertWhenRegisteringSameGasStationTwice() public {
    GasStation gasStation = new GasStation(tokens, 500, 180, "api");
    gasStation.register{value: depositValue}(IGasGateway(this));
    vm.expectRevert("Initializable: contract is already initialized");
    gasStation.register{value: depositValue}(IGasGateway(this));
  }

}
