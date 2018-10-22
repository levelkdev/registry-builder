import lkTestHelpers from 'lk-test-helpers'
const { shouldFail, expectEvent } = lkTestHelpers(web3)
const BigNumber = require('bignumber.js');

const RegistryMock = artifacts.require('RegistryMock.sol')
const Token = artifacts.require('TestToken.sol')
const PLCRVoting = artifacts.require('PLCRVotingMock.sol')
const PLCRVotingChallenge = artifacts.require('PLCRVotingChallenge.sol')

contract('PLCRVotingChallenge', (accounts) => {
  let challenge, registry, plcrVoting, token

  const mockAddresses = [
    '0x4e0100882b427b3be1191c5a7c7e79171b8a24dd',
    '0x6512df5964f1578a8164ce93a3238f2b11485d1c',
    '0x687355ca7a320e5420a3db5ae59ef662e4146786'
  ]

  const CHALLENGER                = accounts[0]
  const LISTING_OWNER             = accounts[1]
  const CHALLENGER_STAKE          = 10 * 10 ** 18
  const COMMIT_STAGE_LENGTH       = 60 * 60 * 24
  const REVEAL_STAGE_LENGTH       = 60 * 60 * 24
  const VOTE_QUORUM               = 50
  const PERCENT_VOTER_REWARD      = 25

  beforeEach(async () => {
    token       = await Token.new([accounts[0], accounts[1], accounts[2]], 100 * 10 ** 18)
    registry    = await RegistryMock.new(token.address)
    plcrVoting  = await PLCRVoting.new(token.address)
    challenge   = await initializeChallenge()
  })

  describe('when deployed with valid parameters', async () => {
    it('sets the challenger address', async () => {
      expect(await challenge.challenger()).to.equal(CHALLENGER)
    })

    it('sets the listingOwner address', async () => {
      expect(await challenge.listingOwner()).to.equal(LISTING_OWNER)
    })

    it('sets the challengerStake', async () => {
      expect((await challenge.challengerStake()).toNumber()).to.equal(CHALLENGER_STAKE)
    })

    it('sets the registry', async () => {
      expect(await challenge.registry()).to.equal(registry.address)
    })

    it('sets voting to the PLCRVoting address', async () => {
      expect(await challenge.voting()).to.equal(plcrVoting.address)
    })

    it('sets the correct pollID', async () => {
      expect((await challenge.pollID()).toNumber()).to.equal(1)
    })

    it('sets the correct voterRewardPool', async () => {
      const voterRewardPool = PERCENT_VOTER_REWARD * CHALLENGER_STAKE / 100
      expect((await challenge.voterRewardPool()).toNumber()).to.equal(voterRewardPool)
    })
  })

  describe('when deployed with invalid parameters', async () => {
    it('reverts if percentVoterReward is over 100', async () => {
      await shouldFail.reverting(initializeChallenge({percentVoterReward: 101}))
    })
  })

  describe('close()', async () => {
    describe('when called under valid conditions', async () => {
      beforeEach(async () => {
        await plcrVoting.set_mock_pollEnded(true)
      })

      it('sets isClosed to true', async () => {
        expect(await challenge.isClosed()).to.equal(false)
        await challenge.close()
        expect(await challenge.isClosed()).to.equal(true)
      })

      it('emits a ChallengeClosed event', async () => {
        const { logs } = await challenge.close()
        await expectEvent.inLogs(logs, 'ChallengeClosed')
      })
    })

    describe('when called under invalid conditions', async () => {

      it('reverts if poll has not yet ended', async () => {
        await shouldFail.reverting(challenge.close())
      })

      it('reverts if close() has already been called successfully', async () => {
        await plcrVoting.set_mock_pollEnded(true)
        await challenge.close()
        shouldFail.reverting(challenge.close())
      })
    })
  })

  describe('passed()', async () => {
    beforeEach(async () => {
      await plcrVoting.set_mock_pollEnded(true)
    })

    it('reverts if challenge is not officially closed', async () => {
      await shouldFail.reverting(challenge.passed())
    })

    it('returns true if the poll in favor of listing has failed', async () => {
      await plcrVoting.set_mock_isPassed(false)
      await challenge.close()
      expect(await challenge.passed()).to.equal(true)
    })

    it('returns fales if the poll in favor of listing has succeeded', async () => {
      await plcrVoting.set_mock_isPassed(true)
      await challenge.close()
      expect(await challenge.passed()).to.equal(false)
    })
  })

  describe('requiredFundsAmount()', async () => {
    it('returns voterRewardPool', async () => {
      let requiredFundsAmount = (await challenge.requiredFundsAmount()).toNumber()
      let voterRewardPool = (await challenge.voterRewardPool()).toNumber()
      expect(requiredFundsAmount).to.equal(voterRewardPool)
    })
  })

  describe('winnerReward()', async () => {
    beforeEach(async () => {
      await plcrVoting.set_mock_pollEnded(true)
    })

    it('reverts if challenge is not officially closed', async () => {
      await shouldFail.reverting(challenge.winnerReward())
    })

    it('returns challengerStake x 2 if no one voted', async () => {
      await challenge.close()
      await plcrVoting.set_mock_getTotalNumberOfTokensForWinningOption(0)
      expect((await challenge.winnerReward()).toNumber()).to.equal(CHALLENGER_STAKE * 2)
    })

    it('returns challengerStake x 2 minus the voterRewardPool if there were voters', async () => {
      const voterRewardPool = (await challenge.voterRewardPool()).toNumber()
      await plcrVoting.set_mock_getTotalNumberOfTokensForWinningOption(5)
      await challenge.close()
      expect((await challenge.winnerReward()).toNumber()).to.equal(CHALLENGER_STAKE * 2 - voterRewardPool)
    })
  })

  describe('claimVoterReward()', async () => {
    let voterTokenAmount, voter, salt

    beforeEach(async () => {
      voterTokenAmount = 10
      voter = accounts[0]
      salt = 123
      await plcrVoting.set_mock_pollEnded(true)
      await plcrVoting.set_mock_getNumPassingTokens(voterTokenAmount)
      await plcrVoting.set_mock_getTotalNumberOfTokensForWinningOption(20)
    })

    it('reverts if challenge is not officially closed', async () => {
      await shouldFail.reverting(challenge.claimVoterReward(salt))
    })

    it('reverts if the sender has already claimed reward', async () => {
      await challenge.close()
      await challenge.claimVoterReward(salt, {from: voter})
      await shouldFail.reverting(challenge.claimVoterReward(salt))
    })

    it('increments voterTokensClaimed by the correct amount', async () => {
      const previousVoterTokensClaimed = (await challenge.voterTokensClaimed()).toNumber()

      await challenge.close()
      await challenge.claimVoterReward(salt, {from: voter})

      const currentVoterTokensClaimed = (await challenge.voterTokensClaimed()).toNumber()
      expect(currentVoterTokensClaimed).to.equal(previousVoterTokensClaimed + voterTokenAmount)
    })

    it('increments voterRewardsClaimed by the correct amount', async () => {
      await challenge.close()
      const voterReward = (await challenge.voterReward(voter, salt)).toNumber()
      const previousVoterRewardsClaimed = (await challenge.voterRewardsClaimed()).toNumber()

      await challenge.claimVoterReward(salt, {from: voter})

      const currentVoterTokensClaimed = (await challenge.voterRewardsClaimed()).toNumber()

      expect(currentVoterTokensClaimed).to.equal(previousVoterRewardsClaimed + voterReward)
    })

    it('tracks that the voter has claimed their tokens', async () => {
      await challenge.close()
      expect(await challenge.tokenClaims(voter)).to.equal(false)
      await challenge.claimVoterReward(salt)
      expect(await challenge.tokenClaims(voter)).to.equal(true)
    })

    it('transfers the correct amount of tokens to the voter', async () => {
      await challenge.close()
      const voterReward = (await challenge.voterReward(voter, salt)).toNumber()
      const previousVoterBalance = (await token.balanceOf(voter)).toNumber()
      await challenge.claimVoterReward(salt, {from: voter})
      const currentVoterBalance = (await token.balanceOf(voter)).toNumber()
      expect(currentVoterBalance).to.equal(previousVoterBalance + voterReward)
    })

    it('emits a RewardClaimed event', async () => {
      await challenge.close()
      const { logs } = await challenge.claimVoterReward(salt, {from: voter})
      await expectEvent.inLogs(logs, 'RewardClaimed')
    })
  })

  describe('voterReward()', async () => {
    let voter, voterTokenAmount, winningTokenAmount, voterRewardPool, voterRewardsClaimed, voterTokensClaimed
    beforeEach(async () => {
      voter = accounts[0]
      voterTokenAmount = 10
      winningTokenAmount = 20
      voterRewardPool = (await challenge.voterRewardPool()).toNumber()
      voterRewardsClaimed = (await challenge.voterRewardsClaimed()).toNumber()
      voterTokensClaimed = (await challenge.voterTokensClaimed()).toNumber()
      await plcrVoting.set_mock_pollEnded(true)
      await plcrVoting.set_mock_getNumPassingTokens(voterTokenAmount)
      await plcrVoting.set_mock_getTotalNumberOfTokensForWinningOption(winningTokenAmount)
    })

    it('returns the correct reward amount', async () => {
      const correctAmount = (voterTokenAmount * (voterRewardPool - voterRewardsClaimed)) / (winningTokenAmount - voterTokensClaimed)
      await challenge.close()
      expect((await challenge.voterReward(voter, 123)).toNumber()).to.equal(correctAmount)
    })
  })

  async function initializeChallenge(customParams = {}) {

    const {
      challenger         = CHALLENGER,
      listingOwner       = LISTING_OWNER,
      challengerStake    = CHALLENGER_STAKE,
      registryAddr       = registry.address,
      plcrVotingAddr     = plcrVoting.address,
      commitStageLength  = COMMIT_STAGE_LENGTH,
      revealStageLength  = REVEAL_STAGE_LENGTH,
      voteQuorum         = VOTE_QUORUM,
      percentVoterReward = PERCENT_VOTER_REWARD
    } = customParams

    let challenge = await PLCRVotingChallenge.new(
      challenger,
      listingOwner,
      challengerStake,
      registryAddr,
      plcrVotingAddr,
      commitStageLength,
      revealStageLength,
      voteQuorum,
      percentVoterReward
    )

    await token.mint(registry.address, 100 * 10 ** 18)
    await registry.mock_approveTokenToChallenge(challenge.address, 1000 * 18 ** 18)
    return challenge
  }
})
