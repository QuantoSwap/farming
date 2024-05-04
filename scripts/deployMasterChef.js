const { ethers, upgrades } = require("hardhat");

const pairs = [
    {address: '', alloc: 0, name: 'QNS/WETH'},
]

const devAddr = '';
const perBlock = '250000000000000000';

async function main() {
    const tokenAddress = '';

    //MasterChef deploy
    const _startBlock = await ethers.provider.getBlockNumber() + 15000;
    const V1contract = await ethers.getContractFactory("MasterChef");

    console.log("Deploying MasterChef...");
    const v1contract = await upgrades.deployProxy(V1contract, [
            tokenAddress,
            devAddr,
            perBlock,
            _startBlock
        ], {initializer: 'initialize'}
    );
    await v1contract.deployed();
    console.log("MasterChef deployed to:", v1contract.address);

    //Add pairs
    const masterChefContract = (await V1contract.attach(v1contract.address))
    for (const pair of pairs) {
        const add = (await masterChefContract.add(pair.alloc, pair.address, false)).wait()
        console.log(`Added ${pair.name} alloc ${pair.alloc} tx ${add.transactionHash}`);
    }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});