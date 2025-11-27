import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import hardhatEthers from "@nomicfoundation/hardhat-ethers";
import { configVariable, defineConfig } from "hardhat/config";
import * as dotenv from "dotenv";

dotenv.config();

export default defineConfig({
  plugins: [hardhatToolboxViemPlugin, hardhatEthers],
  solidity: {
    npmFilesToBuild: [
      "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol",
      "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol",
    ],
    profiles: {
      default: {
        version: "0.8.28",
      },
      production: {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  networks: {
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    hardhatOp: {
      type: "edr-simulated",
      chainType: "op",
    },
    sepolia: {
      type: "http",
      chainId: 11155111,
      // chainType: "l1",
      url: process.env.SEPOLIA_RPC_URL as `http${string}`,
      accounts: [process.env.PRIVATE_KEY1!, process.env.PRIVATE_KEY2!, process.env.PRIVATE_KEY3!, process.env.PRIVATE_KEY4!, process.env.PRIVATE_KEY5!, process.env.PRIVATE_KEY6!],
    },
  }
});
