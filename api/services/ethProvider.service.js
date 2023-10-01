import { ethers, Contract, Wallet } from "ethers";
import * as util from "ethereumjs-util";
import config from "../config.js";

const { PROVIDER_URL, GAS_STATION_ADDRESS, SIGNER_PRIVATE_KEY } = config;

const provider = new ethers.JsonRpcProvider(PROVIDER_URL);

const GasGatewayAbi = [
  "function checkPermit(\
      address owner,\
      address spender,\
      ERC20 token,\
      uint256 value,\
      uint256 deadline,\
      uint8 v,\
      bytes32 r,\
      bytes32 s\
    ) external view;\
  ",
  "function getEthAmount(address token, uint256 amount) external view returns (uint256 ethAmount)"
]

const GasStationAbi = [
  "function gasGateway() public view returns (address)",
  "function exchange(\
      address _wallet,\
      IERC2612 token,\
      uint256 tokenAmount,\
      uint256 _deadline,\
      uint8 v,\
      bytes32 r,\
      bytes32 s) external"
]

const signer = new Wallet(SIGNER_PRIVATE_KEY);

const gasStationContract = new Contract(GAS_STATION_ADDRESS, GasStationAbi, provider);

export default {
  checkPermit: async (input) => {
    const {
      wallet,
      token,
      value,
      deadline,
      signature
    } = input;
    
    const gatewayContract = new Contract(await gasStationContract.gasGateway(), GasGatewayAbi, provider);

    const { v, r, s } = util.fromRpcSig(signature);
    try {
      await gatewayContract.checkPermit(
        wallet,
        GAS_GATEWAY_ADDRESS,
        token,
        value,
        deadline,
        v,
        r,
        s,
      );
    } catch (error) {
      if (error.data) {
        const decodedError = gatewayContract.interface.parseError(error.data);
        throw new Error(decodedError.name);
      } else {
        throw new Error(error.message);
      }
    }
  },

  exchange: async (input) => {
    const {
      wallet,
      token,
      value,
      deadline,
      signature
    } = input;

    const { v, r, s } = util.fromRpcSig(signature);
    await gasStationContract.connect(signer).exchange(wallet, token, amount, deadline, v, r, s);

  }
}
