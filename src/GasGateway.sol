// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IGasStation {
    function tokens() external returns (address[] memory);
    function comission() external returns (uint);
    function twapPeriod() external returns (uint32);
}

interface IGasGateway {
    function register() external payable;
    function deList() external;
    function exchange(address wallet, IERC20 token, uint amount) external payable;
}

interface IPriceOracle {
    function getPriceInEth(address token, uint amount, uint32 twapPeriod) external view returns (uint);
}

contract GasGateway is IGasGateway, Ownable {
    using Address for address payable;

    uint public deposit_value;
    IPriceOracle immutable priceOracle;
    mapping(address => address[]) public gasStations;
    mapping(address => uint) private deposits;
    mapping(address => bool) public deListedGasStations;

    constructor(IPriceOracle _priceOracle) Ownable() {
        priceOracle = _priceOracle;
    }

    function setDeposit(uint value) external onlyOwner {
        deposit_value = value;
    }

    function register() external payable {
        require(payable(msg.sender).isContract(), "Sender is not a contract");
        require(msg.value >= deposit_value, "Not enough ETH for deposit");
        require(deposits[msg.sender] == 0, "Already registered");
        deposits[msg.sender] = msg.value;

        address[] memory tokens = IGasStation(msg.sender).tokens();

        for (uint i=0; i<tokens.length; i++) {
            gasStations[tokens[i]].push(msg.sender);
        }

        if (msg.value > deposit_value) {
            payable(msg.sender).sendValue(msg.value - deposit_value);
        }
    }

    function deList() external {
        require(deposits[msg.sender] > 0, "Gas station is not registered");
        deListedGasStations[msg.sender] = true;
        payable(msg.sender).sendValue(deposits[msg.sender]);
        deposits[msg.sender] = 0;
    }

    function exchange(address wallet, IERC20 token, uint amount) external payable {
        require(deposits[msg.sender] > 0, "Gas station is not registered");
        uint comission = IGasStation(msg.sender).comission();
        uint32 twapPeriod = IGasStation(msg.sender).twapPeriod();
        uint ethAmount = priceOracle.getPriceInEth(address(token), amount, twapPeriod) * (10000 - comission) / 10000;
        require(msg.value >= ethAmount);
        SafeERC20.safeTransferFrom(token, wallet, address(this), amount);
        SafeERC20.safeTransfer(token, msg.sender, amount);
        payable(wallet).sendValue(ethAmount);
        if (msg.value > ethAmount) {
            payable(msg.sender).sendValue(msg.value - ethAmount);
        }
    }
}
