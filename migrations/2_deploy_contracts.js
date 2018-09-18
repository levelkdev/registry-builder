/* global artifacts */

const ShrimpCoin = artifacts.require('ShrimpCoin')

module.exports = function (deployer) {
  deployer.deploy(
    ShrimpCoin
  )
}
