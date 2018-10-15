const web3Utils = require('web3-utils')

const BasicRegistry = artifacts.require('BasicRegistry')

contract('BasicRegistry', () => {
  let basicRegistry, tx

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
        tx = await basicRegistry.add(itemData)
      })

      it('adds the data to the items mapping', async () => {
        expect(await basicRegistry.get(itemId)).to.equal(itemData)
      })

      it.skip('emits an ItemAdded event', () => {
        throw new Error('not implemented')
      })
    })
    describe('when the given data is in the items mapping', () => {
      it.skip('reverts', () => {
        throw new Error('not implemented')
      })
    })
  })
})
