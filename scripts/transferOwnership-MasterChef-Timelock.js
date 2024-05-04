const hre = require("hardhat");
async function main() {
    const MasterChef = await hre.ethers.getContractFactory("MasterChef");

    const timelock = '';
    const masterChef = '';

    const masterChefContract = (await MasterChef.attach(masterChef))
    const transferOwnership = await (await masterChefContract.transferOwnership(timelock)).wait();
    console.log(`Transfer Ownership to Timelock ${transferOwnership.transactionHash}`)

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});