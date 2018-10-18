const { shouldBehaveLikeTimelockableItemRegistry } = require('./TimelockableItemRegistry.behavior')
const { shouldBehaveLikeStakedRegistry } = require('./StakedRegistry.behavior')
const { shouldBehaveLikeOwnedItemRegistry } = require('./OwnedItemRegistry.behavior')
const { shouldBehaveLikeBasicRegistry } = require('./BasicRegistry.behavior')

const TestToken = artifacts.require('TestToken')
const TokenCuratedRegistry = artifacts.require('MockTokenCuratedRegistry')

contract('TokenCuratedRegistry', function (accounts) {

  const [owner, rando] = accounts
  const initialBalance = 100 * 10 ** 18
  const minStake = 10 * 10 ** 18
  const challengeFactoryAddress = '0x9497F19985AE5e02F7A0dEc7FeE521eaE678d0F7'

  beforeEach(async function () {
    this.now = (await web3.eth.getBlock('latest')).timestamp
    this.token = await TestToken.new(
      'TestToken',
      'TEST',
      18,
      [owner, rando],
      initialBalance
    )
  })

  describe('when application period is 0', function () {
    beforeEach(async function () {
      this.registry = await TokenCuratedRegistry.new(
        this.token.address,
        minStake,
        0, // setting applicationPeriod to 0 puts added items into an unlocked state
        challengeFactoryAddress
      )
      await this.token.approve(this.registry.address, minStake, { from: owner })
    })

    shouldBehaveLikeTimelockableItemRegistry(accounts)
    shouldBehaveLikeStakedRegistry(minStake, initialBalance, accounts)
    shouldBehaveLikeOwnedItemRegistry(accounts)
    shouldBehaveLikeBasicRegistry()
  })

})