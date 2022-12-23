const hre = require("hardhat");

const ExtensionAddress = "0x5d2A4C669b9866Bd972C31a64d083489cd3dB480"
const ConsoleAddress = "0xdec44382EAed2954e170BD2a36381A9B06627332"
 
 async function main() {
 
   const contract = await hre.ethers.getContractAt("MonaFortuneTellerExtension", ExtensionAddress);
 
   await contract.initialize(ConsoleAddress).then(() => {
    console.log(
        `Initialized correctly with address ${ConsoleAddress}`
      );
   }).catch((e) => {
    console.log(e["reason"] ? e["reason"] : e["data"] ? e["data"]["message"] : "Undefined")
   })
 
   
 }
 
 // We recommend this pattern to be able to use async/await everywhere
 // and properly handle errors.
 main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });