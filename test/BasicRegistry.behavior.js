const {
  expectEvent,
  shouldFail,
  constants
} = require('lk-test-helpers')(web3)
const parseListingTitle = require('./helpers/parseListingTitle')

const { data: itemData, hash: itemId } = parseListingTitle('listing 001')

const { ZERO_BYTES32 } = constants

function shouldBehaveLikeBasicRegistry(supportedFunctions = [
  'add',
  'remove',
  'get',
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
            expect(await this.registry.get(itemId)).to.equal(itemData)
          })

          it('emits an ItemAdded event', function () {
            expectEvent.inLogs(this.logs, 'ItemAdded', { id: itemId })
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

        describe('when the given id is in the items mapping', function () {
          beforeEach(async function () {
            await this.registry.add(itemData)
            this.logs = (await this.registry.remove(itemId)).logs
          })

          it('removes the data from the items mapping', async function () {
            expect(await this.registry.get(itemId)).to.equal(ZERO_BYTES32)
          })

          it('emits an ItemRemoved event', function () {
            expectEvent.inLogs(this.logs, 'ItemRemoved', { id: itemId })
          })
        })

        describe('when the given id is not in the items mapping', function () {
          it('reverts', async function () {
            await shouldFail.reverting(this.registry.remove(itemId))
          })
        })

      })
    }

    if (supportedFunctions.includes('get')) {
      describe('get()', function () {
        it('returns data for the given id', async function () {
          await this.registry.add(itemData)
          expect(await this.registry.get(itemId)).to.equal(itemData)
        })
      })
    }

    if (supportedFunctions.includes('exists')) {
      describe('exists()', function () {

        describe('when given an id that exists', function () {
          it('returns true', async function () {
            await this.registry.add(itemData)
            expect(await this.registry.exists(itemId)).to.be.true
          })
        })

        describe('when given an id that does not exist', function () {
          it('returns false', async function () {
            expect(await this.registry.exists(itemId)).to.be.false
          })
        })
      })
    }
  })
}

module.exports = {
  shouldBehaveLikeBasicRegistry
}
