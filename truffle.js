require('dotenv').config();
const Web3 = require("web3");
const web3 = new Web3();
const WalletProvider = require("truffle-wallet-provider");
const Wallet = require('ethereumjs-wallet');

var ropstenPrivateKey = new Buffer(process.env["ROPSTEN_PRIVATE_KEY"], "hex");
var ropstenWallet = Wallet.fromPrivateKey(ropstenPrivateKey);
var ropstenProvider = new WalletProvider(ropstenWallet, "https://ropsten.infura.io/");

var mainnetPrivateKey = new Buffer(process.env["MAINNET_PRIVATE_KEY"], "hex");
var mainnetWallet = Wallet.fromPrivateKey(mainnetPrivateKey);
var mainnetProvider = new WalletProvider(mainnetWallet, "https://mainnet.infura.io/");


module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      gas: 4600000,
      network_id: "*" // Match any network id
    },
    ropsten: {
      provider: ropstenProvider,
      network_id: 3,
      gas: 4600000
    },
    mainnet: {
      provider: mainnetProvider,
      network_id: 1,
      gas: 4600000
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
