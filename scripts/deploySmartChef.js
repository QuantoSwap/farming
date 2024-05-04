const hre = require("hardhat");
const {ethers} = require("hardhat");
const BigNumber = require("bignumber.js");

const QNS_TOKEN = '';

const MONTH = 86400 / 0.24 * 30;
const HOUR = 86400 / 0.24 / 24 / 2

const tokens = [
    {
        name: 'USDC',
        addressToken: '',
        stakeToken: QNS_TOKEN,
        perBlock: new BigNumber(1000).div(MONTH).times(1e6).toFixed(0),
        endBlock: MONTH,
        startBlock: HOUR,
        limit: new BigNumber(2000).times(1e18).toFixed(0)
    }
]

async function main() {
    const SmartChef = await hre.ethers.getContractFactory("SmartChef");
    const _startBlock = await ethers.provider.getBlockNumber()
    for (const token of tokens) {
        const contract = await SmartChef.deploy(
            token.stakeToken,
            token.addressToken,
            token.perBlock,
            _startBlock + token.startBlock,
            _startBlock + token.endBlock,
            token.limit
        );
        await contract.deployed();
        console.log(`SmartChef ${token.name} deployed to ${contract.address}`);
        console.log(
            token.stakeToken,
            token.addressToken,
            token.perBlock,
            _startBlock + token.startBlock,
            _startBlock + token.endBlock,
            token.limit
        )
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});