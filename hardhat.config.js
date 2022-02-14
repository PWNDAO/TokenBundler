require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  solidity: {
    version: "0.8.7",
    settings: {
      outputSelection: {
        "*": {
          "*": ["storageLayout"]
        }
      }
    }
  },
  networks: {
    rinkeby: {
      url: process.env.RINKEBY_URL || "",
      accounts:
        process.env.DEPLOY_PRIVATE_KEY_TESTNET !== undefined
          ? [process.env.DEPLOY_PRIVATE_KEY_TESTNET]
          : [],
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      accounts:
        process.env.DEPLOY_PRIVATE_KEY_LOCAL !== undefined
          ? [process.env.DEPLOY_PRIVATE_KEY_LOCAL]
          : [],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
