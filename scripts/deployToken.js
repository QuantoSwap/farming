const hre = require("hardhat");

const preMineReceiver = "";

async function main() {
    //TOKEN deploy
    const Token = await hre.ethers.getContractFactory("QuantoSwapToken");
    const token = await Token.deploy(preMineReceiver);
    await token.deployed();
    console.log(`QuantoSwapToken deployed to ${token.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});