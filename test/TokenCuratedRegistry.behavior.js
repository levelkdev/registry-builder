const { shouldFail, increaseTime } = require('lk-test-helpers')(web3)
const parseListingTitle = require('./helpers/parseListingTitle')

const { data: itemData, hash: itemId } = parseListingTitle('listing 001')

function shouldBehaveLikeTokenCuratedRegistry (
  minStake,
  initialBalance,
  applicationPeriod,
  accounts
) {

  describe('behaves like a TokenCuratedRegistry', function () {
    
    describe('add()', function () {
      beforeEach(async function () {
        await this.registry.add(itemData)
      })

      describe('before applicationPeriod expires', function () {
        it('locks the item', async function () {
          expect(await this.registry.isLocked(itemId)).to.be.true
        })
      })

      describe('after applicationPeriod expires', function () {
        it('unlocks the item', async function () {
          await increaseTime(applicationPeriod + 1)
          expect(await this.registry.isLocked(itemId)).to.be.false
        })
      })

    })

  })

}

module.exports = {
  shouldBehaveLikeTokenCuratedRegistry
}
