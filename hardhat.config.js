require("@nomicfoundation/hardhat-toolbox");
require('@nomiclabs/hardhat-truffle5');
require('@openzeppelin/hardhat-upgrades');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {compilers: [{version: "0.6.12"}, {version: '0.8.3'}, {version: '0.7.0'}]},
  networks: {
    eth: {
      url: 'https://rpc.mevblocker.io',
      accounts: [],
      blockGasLimit: '1000000000',
      allowUnlimitedContractSize: true
    }
  },
  etherscan: {
    apiKey: ''
  }
};
