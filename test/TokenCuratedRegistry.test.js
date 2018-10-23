const { shouldFail, constants } = require('lk-test-helpers')(web3)
const { shouldBehaveLikeTokenCuratedRegistry } = require('./TokenCuratedRegistry.behavior')
const { shouldBehaveLikeTimelockableItemRegistry } = require('./TimelockableItemRegistry.behavior')
const { shouldBehaveLikeStakedRegistry } = require('./StakedRegistry.behavior')
const { shouldBehaveLikeOwnedItemRegistry } = require('./OwnedItemRegistry.behavior')
const { shouldBehaveLikeBasicRegistry } = require('./BasicRegistry.behavior')

const TestToken = artifacts.require('TestToken')
const ChallengeFactory = artifacts.require('MockChallengeFactory')
const TokenCuratedRegistry = artifacts.require('MockTokenCuratedRegistry')

const { ZERO_ADDRESS } = constants

contract('TokenCuratedRegistry', function (accounts) {

  const [owner, challenger, rando] = accounts
  const initialBalance = 100 * 10 ** 18
  const minStake = 10 * 10 ** 18
  const mockChallengeReward = minStake * 2 * 75 / 100
  const mockRequiredFunds = minStake
  const applicationPeriod = 60 * 60

  beforeEach(async function () {
    this.now = (await web3.eth.getBlock('latest')).timestamp
    this.token = await TestToken.new(
      [owner, challenger, rando],
      initialBalance
    )
    this.challengeFactory = await ChallengeFactory.new(mockChallengeReward, mockRequiredFunds)
  })

  describe('when challenge factory address is zero', function () {
    it('contract deployment reverts', async function () {
      await shouldFail.reverting(
        TokenCuratedRegistry.new(
          this.token.address,
          minStake,
          applicationPeriod,
          ZERO_ADDRESS
        )
      )
    })
  })

  describe('when application period is greater than 0', function () {
    beforeEach(async function () {
      this.registry = await TokenCuratedRegistry.new(
        this.token.address,
        minStake,
        applicationPeriod,
        this.challengeFactory.address
      )
      await this.token.approve(this.registry.address, minStake, { from: owner })
    })

    shouldBehaveLikeTokenCuratedRegistry({
      minStake,
      mockChallengeReward,
      initialBalance,
      applicationPeriod,
      accounts
    })
  })

  describe('when application period is 0', function () {
    beforeEach(async function () {
      this.registry = await TokenCuratedRegistry.new(
        this.token.address,
        minStake,
        0, // setting applicationPeriod to 0 puts added items into an unlocked state
        this.challengeFactory.address
      )
      await this.token.approve(this.registry.address, minStake, { from: owner })
    })

    shouldBehaveLikeTimelockableItemRegistry(accounts)
    shouldBehaveLikeStakedRegistry(minStake, initialBalance, accounts)
    shouldBehaveLikeOwnedItemRegistry(accounts)
    shouldBehaveLikeBasicRegistry()
  })

})
