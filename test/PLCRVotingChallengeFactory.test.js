import lkTestHelpers from 'lk-test-helpers'
const { expectRevert, expectEvent, expectThrow } = lkTestHelpers(web3)
const BigNumber = require('bignumber.js');

const RegistryMock = artifacts.require('RegistryMock.sol')
const Token = artifacts.require('TestToken.sol')
const PLCRVoting = artifacts.require('PLCRVotingMock.sol')
const PLCRVotingChallenge = artifacts.require('PLCRVotingChallenge.sol')
const PLCRVotingChallengeFactory = artifacts.require('PLCRVotingChallengeFactory.sol')

contract('PLCRVotingChallengeFactory', (accounts) => {
  let plcrVoting, plcrVotingChallengeFactory, token, registry, challenger, itemOwner


  const mockAddresses = [
    '0x4e0100882b427b3be1191c5a7c7e79171b8a24dd',
    '0x6512df5964f1578a8164ce93a3238f2b11485d1c',
    '0x687355ca7a320e5420a3db5ae59ef662e4146786'
  ]

  const CHALLENGER_STAKE     = 10 * 10 ** 18
  const COMMIT_STAGE_LENGTH  = 60 * 60 * 24
  const REVEAL_STAGE_LENGTH  = 60 * 60 * 24 * 7
  const VOTE_QUORUM          = 51
  const PERCENT_VOTER_REWARD = 15

  beforeEach(async () => {
    token      = await Token.new('TCR Token', 'TCR', 18, [accounts[0], accounts[1], accounts[2]], 100 * 10 ** 18)
    plcrVoting = await PLCRVoting.new(token.address)
    registry = await RegistryMock.new(token.address)
    challenger = accounts[1]
    itemOwner = accounts[2]
  })

  describe('when deployed with valid parameters', () => {
    beforeEach(async () => {
      plcrVotingChallengeFactory = await initializeFactory()
    })

    it('sets the correct challengerStake', async () => {
      expect((await plcrVotingChallengeFactory.challengerStake()).toNumber()).to.equal(CHALLENGER_STAKE)
    })

    it('sets the correct plcrVoting', async () => {
      expect(await plcrVotingChallengeFactory.plcrVoting()).to.equal(plcrVoting.address)
    })

    it('sets the correct commitStageLength', async () => {
      expect((await plcrVotingChallengeFactory.commitStageLength()).toNumber()).to.equal(COMMIT_STAGE_LENGTH)
    })

    it('sets the correct revealStageLength', async () => {
      expect((await plcrVotingChallengeFactory.revealStageLength()).toNumber()).to.equal(REVEAL_STAGE_LENGTH)
    })

    it('sets the correct voteQuorum', async () => {
      expect((await plcrVotingChallengeFactory.voteQuorum()).toNumber()).to.equal(VOTE_QUORUM)

    })
    it('sets the correct percentVoterReward', async () => {
      expect((await plcrVotingChallengeFactory.percentVoterReward()).toNumber()).to.equal(PERCENT_VOTER_REWARD)
    })
  })

  describe('createChallenge()', async () => {
    it('creates a PLCRVotingChallenge with all the correct parameters',async () => {
      plcrVotingChallengeFactory = await initializeFactory()

      const { logs } = await plcrVotingChallengeFactory.createChallenge(registry.address, challenger, itemOwner)
      const event = logs.find(e => e.event === 'PLCRVotingChallengeCreated')
      const challengeAddress = event.args.challenge

      let challenge = PLCRVotingChallenge.at(challengeAddress)
      expect(await challenge.registry()).to.equal(registry.address)
      expect(await challenge.challenger()).to.equal(challenger)
      expect(await challenge.listingOwner()).to.equal(itemOwner)
      expect((await challenge.challengerStake()).toNumber()).to.equal(CHALLENGER_STAKE)
      expect(await challenge.voting()).to.equal(plcrVoting.address)
    })

    it('emits a PLCRVotingChallengeCreated event', async () => {
      const { logs } = await plcrVotingChallengeFactory.createChallenge(registry.address, challenger, itemOwner)
      await expectEvent.inLogs(logs, 'PLCRVotingChallengeCreated')
    })
  })

  async function initializeFactory() {
    return await PLCRVotingChallengeFactory.new(
      CHALLENGER_STAKE,
      plcrVoting.address,
      COMMIT_STAGE_LENGTH,
      REVEAL_STAGE_LENGTH,
      VOTE_QUORUM,
      PERCENT_VOTER_REWARD
    )
  }
})
