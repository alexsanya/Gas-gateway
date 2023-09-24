pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IGasStation {
    function getTokens() external view returns (address[] memory);
    function comission() external view returns (uint16);
    function twapPeriod() external view returns (uint32);
}

interface IGasGateway {
  function depositValue() external view returns (uint);
  function register() external payable;
  function deList() external;
  function getEthAmount(address, uint256) external view returns (uint256);
  function exchange(address wallet, address token, uint256 amount) external payable;
}

interface IPriceOracle {
    function getPriceInEth(address token, uint amount, uint32 twapPeriod) external view returns (uint256);
}
