const hre = require("hardhat");

const ContractAddress = "0x1DEde65FAf4BE8cFd8228215c6AE28d319886335"
const NewAdmin = "0xdec44382EAed2954e170BD2a36381A9B06627332"
 
 async function main() {
 
   const contract = await hre.ethers.getContractAt("MonaFortuneTellerExtension", ContractAddress);
 
   await contract.approveAdmin(NewAdmin);
 
   console.log(
     `New admin has been approved ${NewAdmin}`
   );
 }
 
 // We recommend this pattern to be able to use async/await everywhere
 // and properly handle errors.
 main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });