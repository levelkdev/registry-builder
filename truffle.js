
require('babel-register');
require('babel-polyfill');

const HDWalletProvider = require('truffle-hdwallet-provider');
const fs = require('fs');

// first read in the secrets.json to get our mnemonic
let secrets;
let mnemonic;
if (fs.existsSync('secrets.json')) {
  secrets = JSON.parse(fs.readFileSync('secrets.json', 'utf8'));
  mnemonic = secrets.mnemonic;
} else {
  console.log('no secrets.json found. You can only deploy to the testrpc.');
  mnemonic = '';
}

module.exports = {
  networks: {
    rinkeby: {
      provider: new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io'),
      network_id: '*',
      gas: 6000000,
      gasPrice: 20 * 10 ** 9,
    },
    ropsten: {
      provider: new HDWalletProvider(mnemonic, 'https://ropsten.infura.io'),
      network_id: '*',
      gas: 6000000,
      gasPrice: 20 * 10 ** 9,
    },
    kovan: {
      provider: new HDWalletProvider(mnemonic, 'https://kovan.infura.io'),
      network_id: '*',
      gas: 6000000,
      gasPrice: 20 * 10 ** 9,
    },
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*',
    }
  },
};
