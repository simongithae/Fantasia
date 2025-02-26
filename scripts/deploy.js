const hre = require("hardhat");

async function main(){
    await hre.run('compile');
    const Fantasia = await hre.ethers.getContractFactory("Fantasia");
    const fantasia = await Fantasia.deploy();
    await fantasia.waitForDeployment();

    console.log("Fantasia Contract Address", await todoroles.getAddress())
    

    const FantasiaLSK = await hre.ethers.getContractFactory("FantasiaLSK");
    const fantasialsk = await FantasiaLSK.deploy();
    await fantasialsk.waitForDeployment();

    console.log("FantasiaLSK Contract Address", await todo.getAddress())
}

main().then( ()=> process.exit(0))
.catch(error =>{
    console.error(error);
    process.exit(1);
});