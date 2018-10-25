const {
  expectEvent,
  shouldFail
} = require('lk-test-helpers')(web3)
const parseListingTitle = require('./helpers/parseListingTitle')

const itemData = parseListingTitle('listing 001')

function shouldBehaveLikeBasicRegistry(supportedFunctions = [
  'add',
  'remove',
  'exists'
]) {
  describe('behaves like a BasicRegistry', function () {
    if (supportedFunctions.includes('add')) {
      describe('add()', function () {

        describe('when the given data is not in the items mapping', function () {
          beforeEach(async function () {
            this.logs = (await this.registry.add(itemData)).logs
          })

          it('adds the data to the items mapping', async function () {
            expect(await this.registry.exists(itemData)).to.be.true
          })

          it('emits an ItemAdded event', function () {
            expectEvent.inLogs(this.logs, 'ItemAdded', { data: itemData })
          })
        })

        describe('when the given data is in the items mapping', function () {
          it('reverts', async function () {
            await this.registry.add(itemData)
            await shouldFail.reverting(this.registry.add(itemData))
          })
        })
      })
    }

    if (supportedFunctions.includes('remove')) {
      describe('remove()', function () {

        describe('when the given data is in the items mapping', function () {
          beforeEach(async function () {
            await this.registry.add(itemData)
            this.logs = (await this.registry.remove(itemData)).logs
          })

          it('removes the data from the items mapping', async function () {
            expect(await this.registry.exists(itemData)).to.be.false
          })

          it('emits an ItemRemoved event', function () {
            expectEvent.inLogs(this.logs, 'ItemRemoved', { data: itemData })
          })
        })

        describe('when the given data is not in the items mapping', function () {
          it('reverts', async function () {
            await shouldFail.reverting(this.registry.remove(itemData))
          })
        })

      })
    }

    if (supportedFunctions.includes('exists')) {
      describe('exists()', function () {

        describe('when given data that exists', function () {
          it('returns true', async function () {
            await this.registry.add(itemData)
            expect(await this.registry.exists(itemData)).to.be.true
          })
        })

        describe('when given data that does not exist', function () {
          it('returns false', async function () {
            expect(await this.registry.exists(itemData)).to.be.false
          })
        })
      })
    }
  })
}

module.exports = {
  shouldBehaveLikeBasicRegistry
}
