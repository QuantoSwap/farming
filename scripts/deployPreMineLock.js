const hre = require("hardhat");
const BigNumber = require("bignumber.js");

const _beneficiary = "";
const _token = ''
const _fixedQuantity = new BigNumber(67500).times(1e18).toFixed(0)
const _startTime = Math.floor(Date.now() / 1000);
const _delay = 0;

async function main() {
    const PreMineLock = await hre.ethers.getContractFactory("PreMineTimeLock");
    const contract = await PreMineLock.deploy(_beneficiary, _token, _fixedQuantity, _startTime, _delay, 'lockPreMineTokens');
    await contract.deployed();
    console.log(`PreMineTimeLock Token deployed to ${contract.address}`);
    console.log('data: ', _beneficiary, _token, _fixedQuantity, _startTime, _delay);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});