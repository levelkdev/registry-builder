const { shouldFail } = require('lk-test-helpers')(web3)
const parseListingTitle = require('./helpers/parseListingTitle')

const itemId = parseListingTitle('listing 001')

function shouldBehaveLikeOwnedItemRegistry (accounts) {
  const [owner, rando] = accounts

  describe('behaves like an OwnedItemRegistry', function () {

    describe('when remove() is not called by owner', function () {
      it('reverts', async function () {
        await this.registry.add(itemId, { from: owner })
        await shouldFail.reverting(this.registry.remove(itemId, { from: rando }))
      })
    })

  })
}

module.exports = {
  shouldBehaveLikeOwnedItemRegistry
}
