pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2612.sol";

interface IGasStation {
  function getTokens() external view returns (address[] memory);
  function comission() external view returns (uint16);
  function twapPeriod() external view returns (uint32);
  function deList() external;
  function exchange(address _wallet, IERC2612 token, uint256 tokenAmount, uint256 _deadline, uint8 v, bytes32 r, bytes32 s) external;
  function withdraw(IERC20 token) external;
  function withdrawEth() external;
  function setApiRoot(string memory _apiRoot) external;
  function setTwapPeriod(uint32 _twapPeriod) external;
  function setComission(uint16 _comission) external;
}

interface IGasGateway {
  function depositValue() external view returns (uint);
  function create(address[] memory tokens, uint16 comission, uint32 twapPeriod, string memory apiRoot) external payable returns (address payable);
  function deList() external;
  function getEthAmount(address, uint256) external view returns (uint256);
  function exchange(address wallet, address token, uint256 amount) external payable;
}

interface IPriceOracle {
  function WETH() external view returns (address);
  function getPriceInEth(address token, uint amount, uint32 twapPeriod) external view returns (uint256);
}
