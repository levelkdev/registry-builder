const web3Utils = require('web3-utils')
const { expectEvent, shouldFail } = require('lk-test-helpers')(web3)

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
})
