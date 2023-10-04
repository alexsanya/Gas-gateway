// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "solmate/tokens/ERC20.sol";
import "./Interfaces.sol";
import "./GasStation.sol";

contract GasGateway is IGasGateway, Ownable {
    using Address for address payable;

    uint256 public depositValue;
    IPriceOracle immutable priceOracle;
    mapping(address => address[]) public gasStations;
    mapping(address => uint) private deposits;
    mapping(address => bool) public deListedGasStations;

    constructor(IPriceOracle _priceOracle, uint256 _depositValue) Ownable() {
        priceOracle = _priceOracle;
        depositValue = _depositValue;
    }

    function setDeposit(uint256 value) external onlyOwner {
        depositValue = value;
    }

    function create(address[] memory tokens, uint16 comission, uint32 twapPeriod, string memory apiRoot) external payable returns (address payable) {
        require(msg.value >= depositValue, "Not enough ETH for deposit");
        GasStation gasStation = new GasStation(tokens, comission, twapPeriod, apiRoot);
        gasStation.transferOwnership(msg.sender);
        deposits[address(gasStation)] = msg.value;

        for (uint i=0; i<tokens.length; i++) {
            gasStations[tokens[i]].push(msg.sender);
        }

        if (msg.value > depositValue) {
            payable(msg.sender).sendValue(msg.value - depositValue);
        }
        
        return payable(address(gasStation));
    }

    function deList() external {
        require(deposits[msg.sender] > 0, "Gas station is not registered");
        deListedGasStations[msg.sender] = true;
        payable(msg.sender).sendValue(deposits[msg.sender]);
        deposits[msg.sender] = 0;
    }

    function exchange(address wallet, address token, uint256 amount) external payable {
        require(deposits[msg.sender] > 0, "Gas station is not registered");
        uint ethAmount = _getEthAmount(token, amount);
        require(msg.value >= ethAmount, "Not enough ETH provided");
        SafeERC20.safeTransferFrom(IERC20(token), wallet, address(this), amount);
        SafeERC20.safeTransfer(IERC20(token), msg.sender, amount);
        payable(wallet).sendValue(ethAmount);
        if (msg.value > ethAmount) {
            payable(msg.sender).sendValue(msg.value - ethAmount);
        }
    }

    function _getEthAmount(address token, uint256 amount) internal view returns (uint256 ethAmount) {
      uint comission = IGasStation(msg.sender).comission();
      uint32 twapPeriod = IGasStation(msg.sender).twapPeriod();
      ethAmount = priceOracle.getPriceInEth(address(token), amount, twapPeriod) * (10000 - comission) / 10000;
    }
    
    function getEthAmount(address token, uint256 amount) external view returns (uint256 ethAmount) {
      ethAmount = _getEthAmount(token, amount);
    }

    function checkPermit(
      address owner,
      address spender,
      ERC20 token,
      uint256 value,
      uint256 deadline,
      uint8 v,
      bytes32 r,
      bytes32 s
    ) external view {
      require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
      require(token.balanceOf(owner) >= value, "INSUFFICIENT_BALANCE");


      // Unchecked because the only math done is incrementing
      // the owner's nonce which cannot realistically overflow.

      uint256 nonce = token.nonces(owner);
      unchecked {
        address recoveredAddress = ecrecover(
          keccak256(
            abi.encodePacked(
              "\x19\x01",
              token.DOMAIN_SEPARATOR(),
              keccak256(
                abi.encode(
                  keccak256(
                      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                  ),
                  owner,
                  spender,
                  value,
                  nonce,
                  deadline
                )
              )
            )
          ),
          v,
          r,
          s
        );
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");
      }
    }

}
