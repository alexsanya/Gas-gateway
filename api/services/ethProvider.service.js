import { ethers, Contract, Wallet } from "ethers";
import * as util from "ethereumjs-util";
import config from "../config.js";

const { PROVIDER_URL, GAS_STATION_ADDRESS, SIGNER_PRIVATE_KEY } = config;

const provider = new ethers.JsonRpcProvider(PROVIDER_URL);

const GasGatewayAbi = [
  "function checkPermit(address,address,address,uint256,uint256,uint8,bytes32,bytes32) external view"
]

const GasStationAbi = [
  "function gasGateway() external view returns (address)",
  "function exchange(\
      address _wallet,\
      address token,\
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
    
    const gasGatewayAddress = await gasStationContract.gasGateway();
    const gatewayContract = new Contract(gasGatewayAddress, GasGatewayAbi, provider);

    const { v, r, s } = util.fromRpcSig(signature);
    try {
      await gatewayContract.checkPermit(
        wallet,
        gasGatewayAddress,
        token,
        value,
        deadline,
        v,
        r,
        s,
      );
    } catch (error) {
      if (error.reason) {
        throw new Error(error.reason);
      }
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
