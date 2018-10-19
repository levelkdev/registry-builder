const { shouldFail, constants } = require('lk-test-helpers')(web3)
const { shouldBehaveLikeStakedRegistry } = require('./StakedRegistry.behavior')
const { shouldBehaveLikeOwnedItemRegistry } = require('./OwnedItemRegistry.behavior')
const { shouldBehaveLikeBasicRegistry } = require('./BasicRegistry.behavior')

const StakedRegistry = artifacts.require('MockStakedRegistry')
const TestToken = artifacts.require('TestToken')

const { ZERO_ADDRESS } = constants

contract('StakedRegistry', function (accounts) {
  const [owner, owner2, rando] = accounts
  const initialBalance = 100 * 10 ** 18
  const minStake = 10 * 10 ** 18

  describe('when deployed with valid parameters', function () {
    beforeEach(async function () {
      this.token = await TestToken.new(
        [owner, owner2, rando],
        initialBalance
      )
      this.registry = await StakedRegistry.new(this.token.address, minStake)
      await this.token.approve(this.registry.address, minStake, { from: owner })
    })

    shouldBehaveLikeStakedRegistry(minStake, initialBalance, accounts)
    shouldBehaveLikeOwnedItemRegistry(accounts)
    shouldBehaveLikeBasicRegistry()
  })

  describe('when deployed with 0x0 token address', function () {
    it('reverts', async function () {
      await shouldFail.reverting(StakedRegistry.new(ZERO_ADDRESS, minStake))
    })
  })

})
