require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */


module.exports = {
  solidity: "0.8.18",
  defaultNetwork: "unima1",
  networks: {
    unima1: {
      url: "http://134.155.50.136:8506",
      accounts:["0xea447b8e9a94b24e8cf07047d5d689e547bda6fff22103a2fccea704edfdf541"],
    },
   
    }
  
};

