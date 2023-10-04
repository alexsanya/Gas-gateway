// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/GasStation.sol";
import "./TestToken.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../src/Interfaces.sol";

contract GasStationTest is IGasGateway, Test {
  using Address for address payable;

  IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  uint256 public depositValue = 1 ether;
  address constant IMPOSTER = address(0x1);
  GasStation gasStation;
  IERC20 token;
  address[] tokens;
  
  constructor() {
    tokens.push(address(usdc));
  }

  function setUp() public {
    token = new TestToken();
    payable(IMPOSTER).sendValue(2 ether);
    gasStation = new GasStation{value: 3 ether}(tokens, 500, 180, "api");
  }

  function create(address[] memory tokens, uint16 comission, uint32 twapPeriod, string memory apiRoot) external payable returns (address payable) {
    return payable(address(0));
  }

  function deList() external {}

  function exchange(address wallet, address token, uint256 amount) external payable {}

  function getEthAmount(address, uint256) external view returns (uint256) {}

  receive() external payable {}

  function test_RevertIfComissionExceeds100percent() public {
    vm.expectRevert("Comission cannot exceed 100%");
    GasStation gasStation = new GasStation(tokens, 10001, 180, "api");
  }

  function test_RevertIfTokensListIsEmpty() public {
    vm.expectRevert("Should support at least 1 token");
    new GasStation(new address[](0), 500, 180, "api");
  }

  function test_CreateGasStationAndSetUpParameters() public {
    assertEq(gasStation.comission(), 500);
    assertEq(gasStation.twapPeriod(), 180);
    assertEq(gasStation.apiRoot(), "api");
    assertEq(gasStation.getTokens(), tokens);
    assertEq(address(gasStation).balance, 3 ether);
  }

  function test_RevertDeListIfSenderIsNotOwner() public {
    vm.prank(IMPOSTER);
    vm.expectRevert("Ownable: caller is not the owner");
    gasStation.deList();
  }

  function test_DeListGasStation() public {
    gasStation.deList();
  }

  function test_changeParameters() public {
    gasStation.setComission(1000);
    gasStation.setTwapPeriod(120);
    gasStation.setApiRoot("root");

    assertEq(gasStation.comission(), 1000);
    assertEq(gasStation.twapPeriod(), 120);
    assertEq(gasStation.apiRoot(), "root");
  }

  function test_RevertShouldNotSetComissionMoreThan100Persent() public {
    vm.expectRevert("Comission cannot exceed 100%");
    gasStation.setComission(10001);
  }

  function test_RevertSetComissionIfSenderIsNotAnOwner() public {
    vm.prank(IMPOSTER);
    vm.expectRevert("Ownable: caller is not the owner");
    gasStation.setComission(1000);
  }

  function test_RevertSetTeapPeriodIfSenderIsNotAnOwner() public {
    vm.prank(IMPOSTER);
    vm.expectRevert("Ownable: caller is not the owner");
    gasStation.setTwapPeriod(60);
  }

  function test_RevertSetApiIfSenderIsNotAnOwner() public {
    vm.prank(IMPOSTER);
    vm.expectRevert("Ownable: caller is not the owner");
    gasStation.setApiRoot("newRoot");
  }

  function test_RevertWithdrawIfSenderIsNotAnOwner() public {
    vm.prank(IMPOSTER);
    vm.expectRevert("Ownable: caller is not the owner");
    gasStation.withdraw(token);
  }

  function test_ShouldWithdrawTokens() public {
    token.transfer(address(gasStation), 100);
    uint256 balanceBefore = token.balanceOf(address(this));
    assertEq(token.balanceOf(address(gasStation)), 100);
    gasStation.withdraw(token);
    assertEq(token.balanceOf(address(gasStation)), 0);
    assertEq(token.balanceOf(address(this)), balanceBefore + 100);
  }

  function test_shouldRevertWithdrawEthIfCallerIsNotAnOwner() public {
    vm.prank(IMPOSTER);
    vm.expectRevert("Ownable: caller is not the owner");
    gasStation.withdrawEth();
  }

  function test_ShouldWithdrawEth() public {
    uint256 balanceBefore = address(this).balance;
    gasStation.withdrawEth();
    assertEq(address(gasStation).balance, 0);
    assertEq(address(this).balance, balanceBefore + 3 ether);
  }
}
