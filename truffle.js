
var secretData = require("./secrets.json");
require('dotenv').config();
require('babel-register');
require('babel-polyfill');

require('babel-node-modules')([
  'zeppelin-solidity'
])

var HDWalletProvider = require("truffle-hdwallet-provider");


var infuraRopstenUrl = secretData.INFURA_ROPSTEN_URL;
var infuraMainUrl = secretData.INFURA_MAIN_URL;
var mnemonic = secretData.SECRET_MNEMONIC;
var providerRopsten = new HDWalletProvider(mnemonic, infuraRopstenUrl);
var providerMain = new HDWalletProvider(mnemonic, infuraMainUrl);

console.log("Public key = "+providerMain.address);

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
   development: {
     host: 'localhost',
     port: 8545,
     gas: 5000000,
     network_id: '*', // eslint-disable-line camelcase
   },
    test: {
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      network_id: '*', // eslint-disable-line camelcase
    },
    ropsten: {
      provider: providerRopsten,
      network_id: 3, // eslint-disable-line camelcase
      gasPrice: "3000000000",
      gas: 4600000,
    },
    main: {
      provider: providerMain,
      gasPrice: "3000000000",
      network_id: 99, // eslint-disable-line camelcase
      gas: 5000000,
    }
 }
};
