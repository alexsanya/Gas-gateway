// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/GasGateway.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MockPriceOracle {
  function getPriceInEth(address token, uint amount, uint32 twapPeriod) external pure returns (uint256) {
    return 1 ether;
  }
}

contract GasGatewayTest is Test {
  using Address for address payable;
  using stdStorage for StdStorage;
  GasGateway public gasGateway;
  uint16 public comission = 500; // 5%
  uint32 public twapPeriod = 180;
  IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant USDC_WHALE = address(0xDa9CE944a37d218c3302F6B82a094844C6ECEb17);

  IGasStation gasStation;

  function getTokens() external pure returns (address[] memory) {
    address[] memory _tokens = new address[](1);
    _tokens[0] = address(usdc);
    return _tokens;
  }

  function setUp() public {
    MockPriceOracle mockPriceOracle = new MockPriceOracle();
    gasGateway = new GasGateway(IPriceOracle(address(mockPriceOracle)), 1 ether);
    address[] memory tokens = new address[](1);
    tokens[0] = address(0x1);
    gasStation = IGasStation(gasGateway.create{value: gasGateway.depositValue()}(
      tokens, 500, 180, "api"
    ));
  }

  receive() external payable {}

  function test_RevertIfDeListNotRegisteredGasStation() public {
    vm.expectRevert("Gas station is not registered");
    gasGateway.deList();
  }

  function test_deListShouldReturnDeposit() public {
    uint256 balanceBefore = address(this).balance;
    gasStation.deList();
    assertEq(address(this).balance, balanceBefore + gasGateway.depositValue());
    assertEq(gasGateway.deListedGasStations(address(gasStation)), true);
  }

  function test_exchangeShouldRevertIfGasStationIsNotRegistered() public {
    vm.expectRevert("Gas station is not registered");
    gasGateway.exchange(USDC_WHALE, address(usdc), 100e6);
  }

  function test_exchangeShouldFailIfAmountIsLessThanRequired() public {
    uint256 amount = 100e6;
    uint256 ethRequired = gasGateway.getEthAmount(address(usdc), amount);
    //Found slot number and mark test contract as registered
    vm.store(address(gasGateway), keccak256(abi.encode(address(this),uint256(3))), bytes32(uint256(1)));
    vm.expectRevert("Not enough ETH provided");
    gasGateway.exchange{value: ethRequired - 1}(USDC_WHALE, address(usdc), amount);
  }

  function test_exchangeUSDCToEth() public {
    uint256 amount = 100e6;
    vm.prank(USDC_WHALE);
    usdc.approve(address(gasGateway), amount);
    uint256 ethRequired = gasGateway.getEthAmount(address(usdc), amount);
    uint256 walletEthBefore = USDC_WHALE.balance;
    uint256 walletUsdcBefore = usdc.balanceOf(USDC_WHALE); 
    uint256 gasStationEthBefore = address(this).balance;
    uint256 gasStationUsdcBefore = usdc.balanceOf(address(this));
    //Found slot number and mark test contract as registered
    vm.store(address(gasGateway), keccak256(abi.encode(address(this),uint256(3))), bytes32(uint256(1)));
    gasGateway.exchange{value: ethRequired}(USDC_WHALE, address(usdc), amount);
    assertEq(USDC_WHALE.balance, walletEthBefore + ethRequired);
    assertEq(usdc.balanceOf(USDC_WHALE), walletUsdcBefore - amount);
    assertEq(address(this).balance, gasStationEthBefore - ethRequired);
    assertEq(usdc.balanceOf(address(this)), gasStationUsdcBefore + amount);
  }

  function test_revertSetDepositIfSenderIsNotAnOwner() public {
    vm.prank(USDC_WHALE);
    vm.expectRevert("Ownable: caller is not the owner");
    gasGateway.setDeposit(123);
  }

  function test_detDepositShouldChangeADepositValue() public {
    gasGateway.setDeposit(123);
    assertEq(gasGateway.depositValue(), 123);
  }


}
