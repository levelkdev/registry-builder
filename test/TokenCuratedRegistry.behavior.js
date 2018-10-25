const {
  shouldFail,
  expectEvent,
  increaseTime,
  constants
} = require('lk-test-helpers')(web3)
const chai = require('chai')
const { expect } = chai.use(require('chai-bignumber')(web3.BigNumber))
const parseListingTitle = require('./helpers/parseListingTitle')

const Challenge = artifacts.require('MockChallenge')

const itemData = parseListingTitle('listing 001')
const { ZERO_ADDRESS } = constants

function shouldBehaveLikeTokenCuratedRegistry ({
  minStake,
  mockChallengeReward,
  initialBalance,
  applicationPeriod,
  accounts
}) {
  const [owner, challenger, rando] = accounts

  describe('behaves like a TokenCuratedRegistry', function () {

    describe('add()', function () {
      beforeEach(async function () {
        this.logs = (await this.registry.add(itemData)).logs
      })

      it('emits an Application event', async function () {
        await expectEvent.inLogs(this.logs, 'Application')
      })

      describe('before applicationPeriod expires', function () {
        it('locks the item', async function () {
          expect(await this.registry.isLocked(itemData)).to.be.true
        })
      })

      describe('after applicationPeriod expires', function () {
        it('unlocks the item', async function () {
          await increaseTime(applicationPeriod + 1)
          expect(await this.registry.isLocked(itemData)).to.be.false
        })
      })

    })

    describe('remove()', function () {
      beforeEach(async function () {
        await this.registry.add(itemData)
        await this.registry.setUnlockTime(itemData, 0)
      })

      describe('when there is a challenge for the item', function () {
        beforeEach(async function () {
          this.challenge = await Challenge.new()
          await this.registry.setChallenge(itemData, this.challenge.address)
        })

        it('reverts', async function () {
          await this.challenge.set_mock_passed(true)
          await shouldFail.reverting(this.registry.remove(itemData))
        })
      })
    })

    describe('challenge()', function () {

      describe('when listing item exists, there is no existing challenge for the listing, and token transfer succeeds', function () {
        beforeEach(async function () {
          await this.registry.add(itemData)
          await this.token.approve(this.registry.address, minStake, { from: challenger })
          this.logs = (await this.registry.challenge(itemData, { from: challenger })).logs
          this.challengeAddress = await this.registry.challenges(itemData)
          this.challenge = await Challenge.at(this.challengeAddress)
        })

        it('should transfer stake from the challenger', async function () {
          expect(await this.token.balanceOf(challenger)).to.be.bignumber.equal(initialBalance - minStake)
        })

        it('should approve challenge.fundsRequired() to the challenge ', async function () {
          expect(await this.token.allowance(this.registry.address, this.challengeAddress)).to.be.bignumber.equal(await this.challenge.fundsRequired())
        })

        it('should create challenge with correct params', async function () {
          expect(await this.challengeFactory.registry()).to.equal(this.registry.address)
          expect(await this.challengeFactory.challenger()).to.equal(challenger)
          expect(await this.challengeFactory.itemOwner()).to.equal(owner)
        })

        it('emits a ChallengeInitiated event', async function () {
          await expectEvent.inLogs(this.logs, 'ChallengeInitiated')
        })
      })

      describe('when listing item does not exist', function () {
        it('reverts', async function () {
          await this.token.approve(this.registry.address, minStake, { from: challenger })
          await shouldFail.reverting(this.registry.challenge(itemData, { from: challenger }))
        })
      })

      describe('when challenge for listing item exists', function () {
        it('reverts', async function () {
          await this.registry.add(itemData)
          await this.token.approve(this.registry.address, minStake, { from: challenger })
          await this.registry.challenge(itemData, { from: challenger })
          await this.token.approve(this.registry.address, minStake, { from: rando })
          await shouldFail.reverting(this.registry.challenge(itemData, { from: rando }))
        })
      })

      describe('when challenger stake token transfer fails', function () {
        it('reverts', async function () {
          await this.registry.add(itemData)
          await shouldFail.reverting(this.registry.challenge(itemData, { from: challenger }))
        })
      })

      describe('when challenge.fundsRequired() is greater than the challenge stake', function () {
        it('reverts', async function () {
          await this.registry.add(itemData)
          await this.challengeFactory.mock_set_fundsRequired(minStake * 1.5)
          await this.token.approve(this.registry.address, minStake, { from: challenger })
          await shouldFail.reverting(this.registry.challenge(itemData, { from: challenger }))
        })
      })
    })

    describe('resolveChallenge()', function () {
      describe('when challenge does not exist', async () => {
        it('reverts', async function ()  {
          await this.registry.add(itemData)
          await shouldFail.reverting(this.registry.resolveChallenge(itemData, { from: rando }))
        })
      })

      describe('when challenge exists', function () {
        beforeEach(async function () {
          await this.registry.add(itemData)
          await this.token.approve(this.registry.address, minStake, { from: challenger })
          await this.registry.challenge(itemData, { from: challenger })
          this.challenge = await Challenge.at(await this.registry.challenges(itemData))
        })

        describe('and challenge is not yet closed', async function () {
          it('closes the challenge', async function () {
            expect(await this.challenge.isClosed()).to.be.false
            await this.registry.resolveChallenge(itemData)
            expect(await this.challenge.isClosed()).to.be.true
          })

          shouldCarryOutResolution()
        })

        describe('and challenge is already closed', async function () {
          shouldCarryOutResolution()
        })

        describe('when challenge has passed', function () {
          beforeEach(async function () {
            await this.challenge.set_mock_passed(true)
            this.logs = (await this.registry.resolveChallenge(itemData, { from: rando })).logs
          })

          it('should transfer reward to the challenger', async function () {
            expect(await this.token.balanceOf(challenger)).to.be.bignumber.equal(initialBalance + mockChallengeReward - minStake)
          })

          it('deletes the owner stake', async function () {
            expect(await this.registry.ownerStakes(itemData)).to.be.bignumber.equal(0)
          })

          it('deletes item unlocked state', async function () {
            expect(await this.registry.unlockTimes(itemData)).to.be.bignumber.equal(0)
          })

          it('deletes the item owner', async function () {
            expect(await this.registry.owners(itemData)).to.equal(ZERO_ADDRESS)
          })

          it('deletes the item', async function () {
            expect(await this.registry.exists(itemData)).to.be.false
          })

          it('emits a ChallengeSucceeded event', async function () {
            await expectEvent.inLogs(this.logs, 'ChallengeSucceeded')
          })

          it('emits a ItemRejected event', async function () {
            await expectEvent.inLogs(this.logs, 'ItemRejected')
          })

          shouldCloseChallenge()
          shouldDeleteChallenge()
        })

        describe('when challenge has failed', function () {
          beforeEach(async function () {
            await this.challenge.set_mock_passed(false)
            this.logs = (await this.registry.resolveChallenge(itemData, { from: rando })).logs
          })

          it('adds the reward to the item owner\'s stake', async function () {
            expect(await this.registry.ownerStakes(itemData)).to.be.bignumber.equal(mockChallengeReward)
          })

          it('does not change the item owner', async function () {
            expect(await this.registry.owners(itemData)).to.equal(owner)
          })

          it('does not delete the item', async function () {
            expect(await this.registry.exists(itemData)).to.be.true
          })

          it('unlocks the item', async function () {
            expect(await this.registry.isLocked(itemData)).to.be.false
          })

          it('emits a ChallengeFailed event', async function () {
            await expectEvent.inLogs(this.logs, 'ChallengeFailed')
          })

          shouldCloseChallenge()
          shouldDeleteChallenge()
        })

        function shouldCarryOutResolution() {
          it('carries out the resolution', async function () {
            const winnerReward = await this.challenge.winnerReward()
            const previousItemStake = await this.registry.ownerStakes(itemData)
            await this.challenge.set_mock_passed(false)
            await this.registry.resolveChallenge(itemData)
            const currentItemStake = await this.registry.ownerStakes(itemData)

            expect(previousItemStake).to.be.bignumber.equal(minStake)
            expect(currentItemStake).to.be.bignumber.equal(winnerReward)
            expect(await this.registry.challenges(itemData)).to.equal(ZERO_ADDRESS)
          })
        }

        function shouldCloseChallenge () {
          it('closes the challenge', async function () {
            expect(await this.challenge.isClosed()).to.be.true
          })
        }

        function shouldDeleteChallenge () {
          it('deletes the challenge from the registry', async function () {
            expect(await this.registry.challenges(itemData)).to.equal(ZERO_ADDRESS)
          })
        }
      })
    })

    describe('inApplicationPhase()', function () {
      describe('when item exists', function () {
        beforeEach(async function () {
          await this.registry.add(itemData)
        })

        describe('and item is locked', function () {
          it('returns true', async function () {
            await this.registry.setUnlockTime(itemData, this.now + 1000)
            expect(await this.registry.inApplicationPhase(itemData)).to.be.true
          })
        })

        describe('and item is not locked', function () {
          it('returns false', async function () {
            await this.registry.setUnlockTime(itemData, 0)
            expect(await this.registry.inApplicationPhase(itemData)).to.be.false
          })
        })
      })

      describe('when item does not exist', function () {
        it('reverts', async function () {
          await shouldFail.reverting(this.registry.inApplicationPhase(itemData))
        })
      })
    })

    describe('challengeExists()', function () {
      describe('when item exists', function () {
        beforeEach(async function () {
          await this.registry.add(itemData)
        })

        describe('and challenge exists', function () {
          it('returns true', async function () {
            await this.token.approve(this.registry.address, minStake, { from: challenger })
            await this.registry.challenge(itemData, { from: challenger })
            expect(await this.registry.challengeExists(itemData)).to.be.true
          })
        })

        describe('and challenge does not exist', function () {
          it('returns false', async function () {
            expect(await this.registry.challengeExists(itemData)).to.be.false
          })
        })
      })

      describe('when item does not exist', function () {
        it('reverts', async function () {
          await shouldFail.reverting(this.registry.challengeExists(itemData))
        })
      })
    })
  })
}

module.exports = {
  shouldBehaveLikeTokenCuratedRegistry
}
