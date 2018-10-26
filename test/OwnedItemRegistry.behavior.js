const { shouldFail } = require('lk-test-helpers')(web3)
const parseListingTitle = require('./helpers/parseListingTitle')

const itemData = parseListingTitle('listing 001')

function shouldBehaveLikeOwnedItemRegistry (accounts) {
  const [owner, rando] = accounts

  describe('behaves like an OwnedItemRegistry', function () {

    describe('when remove() is not called by owner', function () {
      it('reverts', async function () {
        await this.registry.add(itemData, { from: owner })
        await shouldFail.reverting(this.registry.remove(itemData, { from: rando }))
      })
    })

  })
}

module.exports = {
  shouldBehaveLikeOwnedItemRegistry
}
