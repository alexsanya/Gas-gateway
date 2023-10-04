import { ethers, Contract, ContractFactory, Wallet } from "ethers";
import config from "./config.js";
import priceOracleArtifact from "../out/PriceOracle.sol/PriceOracle.json" assert { type: 'json' };
import gasGatewayArtifact from "../out/GasGateway.sol/GasGateway.json" assert { type: 'json' };
import gasStationArtifact from "../out/GasStation.sol/GasStation.json" assert { type: 'json' };
import fundUSDCArtifact from "../out/FundUSDC.sol/FundUSDC.json" assert { type: 'json' };

const { PROVIDER_URL, SIGNER_PRIVATE_KEY } = config;

const provider = new ethers.providers.JsonRpcProvider(PROVIDER_URL);
const signer = new Wallet(SIGNER_PRIVATE_KEY, provider);
const customer = new Wallet("08d11cc57eca3df70d53ad570de0f2c6926c33fb93bc16fb9b9dcd25d54818bf", provider);

const DEPOSIT_VALUE = 5n * 10n ** 17n; // 0.5 ETH
const USDC = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";

const ERC20abi = [
  "function name() external view returns (string memory)",
  "function version() external view returns (string memory)",
  "function nonces(address) external view returns (uint256)",
  "function balanceOf(address) external view returns (uint256)",
  "function transfer(address, uint256) external returns (bool)",
  "function permit(\
        address owner,\
        address spender,\
        uint256 value,\
        uint256 deadline,\
        uint8 v,\
        bytes32 r,\
        bytes32 s\
  ) public"
]
const usdcContract = new Contract(USDC, ERC20abi, provider);


async function setUp() {
  // deploy contracts
  const priceOracleContract = await deployContract('PriceOracle', priceOracleArtifact);
  const priceOracleAddress = await priceOracleContract.address;
  const gasGatewayContract = await deployContract('GasGateway', gasGatewayArtifact, priceOracleAddress, DEPOSIT_VALUE);
  const gasGatewayAddress = await gasGatewayContract.address;

  const gasStationAddress = await gasGatewayContract.connect(signer).callStatic.create([USDC], 5000, 180, "apiRoot", { value: DEPOSIT_VALUE });
  let tx = await gasGatewayContract.connect(signer).create([USDC], 5000, 180, "apiRoot", { value: DEPOSIT_VALUE });
  await tx.wait();
  console.log({ gasStationAddress });
  const gasStationContract = new Contract(gasStationAddress, gasStationArtifact.abi, provider);

  const fundUSDCcontract = await deployContract('FundUSDC', fundUSDCArtifact);
  // fund gas station
  tx = await signer.sendTransaction({
    to: gasStationAddress,
    value: 2n * DEPOSIT_VALUE
  });
  await tx.wait();
  console.log(`Gas station ${gasStationAddress} has a balance of ${await provider.getBalance(gasStationAddress)} wei`);
  
  //fund wallet with USDC
  tx = await fundUSDCcontract.swapExactOutputSingle(100e6, 2n * DEPOSIT_VALUE, { value: 2n * DEPOSIT_VALUE });
  await tx.wait();
  console.log(`Deployer USDC ballance is ${await usdcContract.balanceOf(signer.address)}`);
  tx = await usdcContract.connect(signer).transfer(customer.address, 100e6);
  await tx.wait();
  console.log(`Customer USDC ballance is ${await usdcContract.balanceOf(customer.address)}`);
  console.log(`Customer ETH ballance is ${await provider.getBalance(customer.address)}`);
  //prepare signature
  const { signature, deadline } = await getSignature(gasGatewayAddress);
  console.log({ signature, deadline });
  
}

async function getSignature(gasGatewayAddress) {

  const chainId = (await provider.getNetwork()).chainId;
  // set the domain parameters
  const domain = {
    name: await usdcContract.name(),
    version: await usdcContract.version(),
    chainId: chainId,
    verifyingContract: USDC
  };

  console.log(domain);

  // set the Permit type parameters
  const types = {
    Permit: [{
        name: "owner",
        type: "address"
      },
      {
        name: "spender",
        type: "address"
      },
      {
        name: "value",
        type: "uint256"
      },
      {
        name: "nonce",
        type: "uint256"
      },
      {
        name: "deadline",
        type: "uint256"
      },
    ],
  };
  const deadline = (await provider.getBlock("latest")).timestamp + 3600000;
  const values = {
    owner: customer.address,
    spender: gasGatewayAddress,
    value: 100e6,
    nonce: await usdcContract.nonces(customer.address),
    deadline
  };
  console.log("Values: ", values);
  const signature = await customer._signTypedData(domain, types, values);

  const { v, r, s } = ethers.utils.splitSignature(signature);
  console.log({ v, r, s});

  const nonce = await usdcContract.nonces(customer.address);
  console.log({ nonce });

  return { signature, deadline};
}

async function deployContract(name, artifact, ...constructorArgs) {
  const { abi, bytecode } = artifact
  const factory = new ContractFactory(abi, bytecode, signer);
  const contract = await factory.deploy(...constructorArgs);
  await contract.deployTransaction.wait();
  console.log(`Contract ${name} deployed at address ${await contract.address}`);
  return contract;
}

setUp();
