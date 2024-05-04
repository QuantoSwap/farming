const hre = require("hardhat");

const admin = "";

async function main() {
    const Withdrawal = await hre.ethers.getContractFactory("QuantoSwapWithdrawals");
    const withdrawal = await Withdrawal.deploy(admin);
    await withdrawal.deployed();
    console.log(`QuantoSwap withdrawals deployed to ${withdrawal.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});