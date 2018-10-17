const { shouldFail } = require('lk-test-helpers')(web3)
const { shouldBehaveLikeBasicRegistry } = require('./BasicRegistry.behavior')
const parseListingTitle = require('./helpers/parseListingTitle')

const { data: itemData, hash: itemId } = parseListingTitle('listing 001')

function shouldBehaveLikeOwnedItemRegistry (accounts) {
  const [owner, rando] = accounts

  shouldBehaveLikeBasicRegistry()

  describe('when remove() is not called by owner', function () {
    it('reverts', async function () {
      await this.registry.add(itemData, { from: owner })
      await shouldFail.reverting(this.registry.remove(itemId, { from: rando }))
    })
  })
}

module.exports = {
  shouldBehaveLikeOwnedItemRegistry
}
