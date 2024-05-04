const { ethers, upgrades } = require("hardhat");

const UPGRADEABLE_PROXY = "";

async function main() {
    const V2Contract = await ethers.getContractFactory("MasterChef");
    console.log("Upgrading MasterChef...");
    let upgrade = await upgrades.upgradeProxy(UPGRADEABLE_PROXY, V2Contract);
    console.log("V1 Upgraded to V2");
    console.log("V2 Contract MasterChef Deployed To:", upgrade.address)
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});