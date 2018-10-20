const { shouldBehaveLikeStakedRegistry } = require('./StakedRegistry.behavior')
const { shouldBehaveLikeOwnedItemRegistry } = require('./OwnedItemRegistry.behavior')
const { shouldBehaveLikeBasicRegistry } = require('./BasicRegistry.behavior')

const StakedRegistry = artifacts.require('MockStakedRegistry')
const TestToken = artifacts.require('TestToken')

contract('StakedRegistry', function (accounts) {
  const [owner, owner2, rando] = accounts
  const initialBalance = 100 * 10 ** 18
  const minStake = 10 * 10 ** 18

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
