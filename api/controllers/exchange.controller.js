import config from "../config.js";
import ethProvider from "../services/ethProvider.service.js";
import statusService from "../services/statusService.service.js";
import { getLogger } from '../utils/logger.util.js';

const logger = getLogger('Exchange controller');

async function validateInput(input) {
  const ethAddressTemplate = /(0x[a-f0-9]{40})/g;
  const {
    wallet,
    token,
    value,
    deadline,
    signature
  } = input;

  const { MIN_VALUE, TOKENS } = config;

  if (!ethAddressTemplate.exec(wallet)) {
    throw new Error("Wallet address has wrong format");
  }

  if (!TOKENS.includes(token)) {
    throw new Error("Choosen token is not supported");
  }

  if (BigInt(value) < MIN_VALUE) {
    throw new Error(`Value should be not less then ${MIN_VALUE} wei`);
  }

  if (isNaN(parseInt(deadline))) {
    throw new Error('Deadline has wrong format');
  }

  try {
    await ethProvider.checkPermit(input);
  } catch (error) {
    logger.error(error);
    throw new Error(error.message);
  }

}

async function exchange(input) {
  try {
    statusService.setBusy();
    const hash = await ethProvider.exchange(input);
    statusService.setFree(hash);
    return { transaction: hash };
  } catch (error) {
    logger.error(error);
    statusService.setFree();
    throw new Error(error.message);
  }
}

export default {
  validateInput,
  exchange
}
