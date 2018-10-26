const { shouldFail } = require('lk-test-helpers')(web3)
const parseListingTitle = require('./helpers/parseListingTitle')

const itemData = parseListingTitle('listing 001')

function shouldBehaveLikeTimelockableItemRegistry () {

  describe('behaves like a TimelockableItemRegistry', function () {

    describe('when remove() is called on a locked item', function () {
      it('reverts', async function () {
        await this.registry.add(itemData)
        await this.registry.setUnlockTime(itemData, this.now + 1000)
        await shouldFail.reverting(this.registry.remove(itemData))
      })
    })

    describe('isLocked()', function () {
      describe('when item exists', function () {
        beforeEach(async function () {
          await this.registry.add(itemData)
        })

        describe('when item unlock time is less than `now`', function () {
          it('returns true', async function () {
            await this.registry.setUnlockTime(itemData, this.now + 1000)
            expect(await this.registry.isLocked(itemData)).to.be.true
          })
        })

        describe('when item unlock time is greater than `now`', function () {
          it('returns false', async function () {
            await this.registry.setUnlockTime(itemData, this.now - 1000)
            expect(await this.registry.isLocked(itemData)).to.be.false
          })
        })
      })

      describe('when item does not exist', function () {
        it('reverts', async function () {
          await shouldFail.reverting(this.registry.isLocked(itemData))
        })
      })
    })
  })

}

module.exports = {
  shouldBehaveLikeTimelockableItemRegistry
}
