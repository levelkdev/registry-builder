const {
  expectEvent,
  shouldFail
} = require('lk-test-helpers')(web3)
const parseListingTitle = require('./helpers/parseListingTitle')

const itemId = parseListingTitle('listing 001')

function shouldBehaveLikeBasicRegistry(supportedFunctions = [
  'add',
  'remove',
  'exists'
]) {
  describe('behaves like a BasicRegistry', function () {
    if (supportedFunctions.includes('add')) {
      describe('add()', function () {

        describe('when the given id is not in the items mapping', function () {
          beforeEach(async function () {
            this.logs = (await this.registry.add(itemId)).logs
          })

          it('adds the id to the items mapping', async function () {
            expect(await this.registry.exists(itemId)).to.be.true
          })

          it('emits an ItemAdded event', function () {
            expectEvent.inLogs(this.logs, 'ItemAdded', { id: itemId })
          })
        })

        describe('when the given id is in the items mapping', function () {
          it('reverts', async function () {
            await this.registry.add(itemId)
            await shouldFail.reverting(this.registry.add(itemId))
          })
        })
      })
    }

    if (supportedFunctions.includes('remove')) {
      describe('remove()', function () {

        describe('when the given id is in the items mapping', function () {
          beforeEach(async function () {
            await this.registry.add(itemId)
            this.logs = (await this.registry.remove(itemId)).logs
          })

          it('removes the id from the items mapping', async function () {
            expect(await this.registry.exists(itemId)).to.be.false
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

    if (supportedFunctions.includes('exists')) {
      describe('exists()', function () {

        describe('when given id that exists', function () {
          it('returns true', async function () {
            await this.registry.add(itemId)
            expect(await this.registry.exists(itemId)).to.be.true
          })
        })

        describe('when given id that does not exist', function () {
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
