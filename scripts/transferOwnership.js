const hre = require("hardhat");
async function main() {
    const Token = await hre.ethers.getContractFactory("QuantoSwapToken");

    const tokenAddress = '';
    const masterChef = '';

    //Transfer Ownership to MasterChef
    const tokenContract = (await Token.attach(tokenAddress))
    const transferOwnership = await (await tokenContract.transferOwnership(masterChef)).wait();
    console.log(`Transfer Ownership to MasterChef ${transferOwnership.transactionHash}`)

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});