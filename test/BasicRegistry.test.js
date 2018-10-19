const web3Utils = require('web3-utils')
const {
  expectEvent,
  shouldFail,
  constants
} = require('lk-test-helpers')(web3)

const { ZERO_BYTES32 } = constants

const BasicRegistry = artifacts.require('BasicRegistry')

contract('BasicRegistry', () => {
  let basicRegistry, logs

  const itemData = web3Utils.padRight(
    web3Utils.fromAscii('listing 001'),
    64
  )
  const itemId = web3Utils.keccak256(itemData)

  beforeEach(async () => {
    basicRegistry = await BasicRegistry.new()
  })

  describe('add()', () => {

    describe('when the given data is not in the items mapping', () => {
      beforeEach(async () => {
        logs = (await basicRegistry.add(itemData)).logs
      })

      it('adds the data to the items mapping', async () => {
        expect(await basicRegistry.get(itemId)).to.equal(itemData)
      })

      it('emits an ItemAdded event', () => {
        expectEvent.inLogs(logs, 'ItemAdded', { id: itemId })
      })
    })
  
    describe('when the given data is in the items mapping', () => {
      it('reverts', async () => {
        await basicRegistry.add(itemData)
        await shouldFail.reverting(basicRegistry.add(itemData))
      })
    })
  })

  describe('remove()', () => {

    describe('when the given id is in the items mapping', () => {
      beforeEach(async () => {
        await basicRegistry.add(itemData)
        logs = (await basicRegistry.remove(itemId)).logs
      })

      it('removes the data from the items mapping', async () => {
        expect(await basicRegistry.get(itemId)).to.equal(ZERO_BYTES32)
      })

      it('emits an ItemRemoved event', () => {
        expectEvent.inLogs(logs, 'ItemRemoved', { id: itemId })
      })
    })

    describe('when the given id is not in the items mapping', () => {
      it('reverts', async () => {
        await shouldFail.reverting(basicRegistry.remove(itemId))
      })
    })

  })

  describe('get()', () => {
    it('returns data for the given id', async () => {
      await basicRegistry.add(itemData)
      expect(await basicRegistry.get(itemId)).to.equal(itemData)
    })
  })

  describe('exists()', () => {

    describe('when given an id that exists', () => {
      it('returns true', async () => {
        await basicRegistry.add(itemData)
        expect(await basicRegistry.exists(itemId)).to.be.true
      })
    })

    describe('when given an id that does not exist', () => {
      it('returns false', async () => {
        expect(await basicRegistry.exists(itemId)).to.be.false
      })
    })
  })

})
