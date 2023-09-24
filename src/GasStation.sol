// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2612.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Interfaces.sol";

contract GasStation is Ownable, Initializable {
  using Address for address payable;

  address[] public tokens;
  IGasGateway public gasGateway;
  uint16 public comission;
  uint32 public twapPeriod;
  string public apiRoot;

  constructor(address[] memory _tokens, uint16 _comission, uint32 _twapPeriod, string memory _apiRoot) payable Ownable() {
    require(_comission < 10000, "Comission cannot exceed 100%");
    require(_tokens.length > 0, "Should support at least 1 token");
    for (uint8 i=0; i < _tokens.length; i++) {
      tokens.push(_tokens[i]);
    }
    comission = _comission;
    twapPeriod = _twapPeriod;
    apiRoot = _apiRoot;
  }

  function getTokens() external view returns (address[] memory) {
    return tokens;
  }

  function register(IGasGateway _gasGateway) external payable initializer onlyOwner {
    require(msg.value >= _gasGateway.depositValue(), "Not enough eth for deposit");
    _gasGateway.register{value: msg.value}();
    gasGateway = _gasGateway;
  }

  function deList() external onlyOwner {
    gasGateway.deList();
    payable(msg.sender).sendValue(address(this).balance);
  }

  function setComission(uint16 _comission) external onlyOwner {
    require(_comission < 10000, "Comission cannot exceed 100%");
    comission = _comission;
  }

  function setTwapPeriod(uint32 _twapPeriod) external onlyOwner {
    twapPeriod = _twapPeriod;
  }

  function setApiRoot(string memory _apiRoot) external onlyOwner {
    apiRoot = _apiRoot;
  }

  function exchange(address _wallet, IERC2612 token, uint256 tokenAmount, uint256 _deadline, uint8 v, bytes32 r, bytes32 s) external {
    token.permit(
        _wallet,
        address(gasGateway),
        tokenAmount,
        _deadline,
        v,
        r,
        s
    );
    uint256 ethRequired = gasGateway.getEthAmount(address(token), tokenAmount);
    gasGateway.exchange{ value: ethRequired }(_wallet, address(token), tokenAmount);
  }

  function withdraw(IERC20 token) external onlyOwner {
    SafeERC20.safeTransfer(token, msg.sender, token.balanceOf(address(this)));
  }

  function withdrawEth() external onlyOwner {
    require(address(this).balance > 0, "Nothing to transfer");
    payable(msg.sender).sendValue(address(this).balance);
  }

  receive() external payable {

  }

}
