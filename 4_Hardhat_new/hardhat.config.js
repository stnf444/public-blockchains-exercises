require("@nomicfoundation/hardhat-toolbox");

/** @type import 4_Hardhat_new/Lock.sol */
module.exports = {
  solidity: "0.8.18",
  defaultNetwork: unima1,
  networks: {
    unima1: {
      url: process.env.NOT_UNIMA_URL_1,
      accounts:["METAMASK_1_PRIVATE_KEY_1"],
    },
    unima2: {
      url: process.env.NOT_UNIMA_URL_2,
      accounts: ["METAMASK_1_PRIVATE_KEY_1"],
    },
    UniMa: {
      chainId: 1337,
      url: "http://134.155.50.125:8506",
      accounts: ["METAMASK_1_PRIVATE_KEY_1"],
      gasPrice: 20000000000, // 20 gwei
      gas: 8000000 // 8 million gas limit
    }
  }
};
