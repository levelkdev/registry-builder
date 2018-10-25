const web3Utils = require('web3-utils')

module.exports = (listingTitle) => {
  return web3Utils.padRight(
    web3Utils.fromAscii(listingTitle),
    64
  )
}
