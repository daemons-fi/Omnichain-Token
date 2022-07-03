import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";

require("dotenv").config();
const PRIVATE_KEY = process.env.PRIVATE_KEY;
if (!PRIVATE_KEY) throw new Error("PRIVATE_KEY not defined!");

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    networks: {
        arb_rinkeby_testnet: {
            url: "https://rinkeby.arbitrum.io/rpc",
            chainId: 421611,
            accounts: [PRIVATE_KEY],
            gas: 2100000
        },
        ftm_testnet: {
            url: "https://rpc.testnet.fantom.network/",
            chainId: 4002,
            accounts: [PRIVATE_KEY]
        }
    },
    solidity: {
        version: "0.8.4",
        settings: {
            optimizer: {
                enabled: true,
                runs: 1000
            }
        }
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    mocha: {
        timeout: 20000
    }
};

export default config;
