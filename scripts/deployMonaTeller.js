const hre = require("hardhat");

/** 
 * ETH / USD Price feed
 * Goerli Address : 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
 * Mainnet Address : 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
 */
 const PriceFeedAddr = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"
 
 async function main() {
 
   const Contract = await hre.ethers.getContractFactory("MonaFortuneTellerExtension");
   const contract = await Contract.deploy(PriceFeedAddr);
 
   await contract.deployed();
 
   console.log(
     `MonaFortuneTeller deployed to ${contract.address} with this ${PriceFeedAddr} price feed.`
   );
 }
 
 // We recommend this pattern to be able to use async/await everywhere
 // and properly handle errors.
 main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });