const hre = require("hardhat");

async function main() {

  const signers = await hre.ethers.getSigners();
  const deployer = signers[0];


  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
 
  const RPS = await hre.ethers.getContractFactory("RPS");
  const deployedRPS = await RPS.deploy();

  await deployedRPS.deployed();

  console.log("RPS deployed to:", deployedRPS.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
