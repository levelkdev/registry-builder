const web3Utils = require('web3-utils')

module.exports = (listingTitle) => {
  const data = web3Utils.padRight(
    web3Utils.fromAscii(listingTitle),
    64
  )

  const hash = web3Utils.keccak256(data)

  return { data, hash }
}
