const {
  shouldFail,
  increaseTime,
  constants
} = require('lk-test-helpers')(web3)
const chai = require('chai')
const { expect } = chai.use(require('chai-bignumber')(web3.BigNumber))
const parseListingTitle = require('./helpers/parseListingTitle')

const Challenge = artifacts.require('MockChallenge')

const { data: itemData, hash: itemId } = parseListingTitle('listing 001')
const { ZERO_BYTES32, ZERO_ADDRESS } = constants

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
        await this.registry.add(itemData)
      })

      describe('before applicationPeriod expires', function () {
        it('locks the item', async function () {
          expect(await this.registry.isLocked(itemId)).to.be.true
        })
      })

      describe('after applicationPeriod expires', function () {
        it('unlocks the item', async function () {
          await increaseTime(applicationPeriod + 1)
          expect(await this.registry.isLocked(itemId)).to.be.false
        })
      })

    })

    describe('remove()', function () {
      beforeEach(async function () {
        await this.registry.add(itemData)
        this.registry.setUnlockTime(itemId, 0)
      })

      describe('when there is a challenge for the item', function () {
        beforeEach(async function () {
          this.challenge = await Challenge.new()
          await this.registry.setChallenge(itemId, this.challenge.address)
        })
        
        describe('and the challenge has failed', function () {
          beforeEach(async function () {
            await this.challenge.set_mock_passed(false)
            await this.registry.remove(itemId)
          })

          it('removes the item', async function () {
            expect(await this.registry.get(itemId)).to.equal(ZERO_BYTES32)
          })

          it('deletes the challenge from the challenges mapping', async function () {
            expect(await this.registry.challenges(itemId)).to.equal(ZERO_ADDRESS)
          })
        })

        describe('and the challenge has passed', function () {
          it('reverts', async function () {
            await this.challenge.set_mock_passed(true)
            await shouldFail.reverting(this.registry.remove(itemId))
          })
        })
      })
    })

    describe('challenge()', function () {

      describe('when listing item exists, there is no existing challenge for the listing, and token transfer succeeds', function () {
        beforeEach(async function () {
          await this.registry.add(itemData)
          await this.token.approve(this.registry.address, minStake, { from: challenger })
          await this.registry.challenge(itemId, { from: challenger })
          this.challengeAddress = await this.registry.challenges(itemId)
        })

        it('should transfer stake from the challenger', async function () {
          expect(await this.token.balanceOf(challenger)).to.be.bignumber.equal(initialBalance - minStake)
        })

        it('should transfer owner and challenger stake to the challenge', async function () {
          expect(await this.token.balanceOf(this.challengeAddress)).to.be.bignumber.equal(minStake * 2)
        })

        it('should transfer owner stake from the registry', async function () {
          expect(await this.token.balanceOf(this.registry.address)).to.be.bignumber.equal(0)
        })

        it('should create challenge with correct params', async function () {
          expect(await this.challengeFactory.registry()).to.equal(this.registry.address)
          expect(await this.challengeFactory.challenger()).to.equal(challenger)
          expect(await this.challengeFactory.itemOwner()).to.equal(owner)
        })
      })

      describe('when listing item does not exist', function () {
        it('reverts', async function () {
          await this.token.approve(this.registry.address, minStake, { from: challenger })
          await shouldFail.reverting(this.registry.challenge(itemId, { from: challenger }))
        })
      })

      describe('when challenge for listing item exists', function () {
        it('reverts', async function () {
          await this.registry.add(itemData)
          await this.token.approve(this.registry.address, minStake, { from: challenger })
          await this.registry.challenge(itemId, { from: challenger })
          await this.token.approve(this.registry.address, minStake, { from: rando })
          await shouldFail.reverting(this.registry.challenge(itemId, { from: rando }))
        })
      })

      describe('when challenger stake token transfer fails', function () {
        it('reverts', async function () {
          await this.registry.add(itemData)
          await shouldFail.reverting(this.registry.challenge(itemId, { from: challenger }))
        })
      })

    })

    describe('resolveChallenge()', function () {
      describe('when challenge exists', function () {
        beforeEach(async function () {
          await this.registry.add(itemData)
          await this.token.approve(this.registry.address, minStake, { from: challenger })
          await this.registry.challenge(itemId, { from: challenger })
          this.challenge = await Challenge.at(await this.registry.challenges(itemId))
          await this.challenge.approveRewardTransfer(this.token.address, this.registry.address)
        })

        describe('when challenge has passed', function () {
          beforeEach(async function () {
            await this.challenge.set_mock_passed(true)
            await this.registry.resolveChallenge(itemId, { from: rando })
          })

          it('should transfer reward to the challenger', async function () {
            expect(await this.token.balanceOf(challenger)).to.be.bignumber.equal(initialBalance + mockChallengeReward - minStake)
          })

          it('deletes the owner stake', async function () {
            expect(await this.registry.ownerStakes(itemId)).to.be.bignumber.equal(0)
          })

          it('deletes item unlocked state', async function () {
            expect(await this.registry.unlockTimes(itemId)).to.be.bignumber.equal(0)
          })

          it('deletes the item owner', async function () {
            expect(await this.registry.owners(itemId)).to.equal(ZERO_ADDRESS)
          })

          it('deletes the item', async function () {
            expect(await this.registry.exists(itemId)).to.be.false
          })

          shouldCloseChallenge()
          shouldDeleteChallenge()
          shouldTransferRewardFromChallenge()
        })

        describe('when challenge has failed', function () {
          beforeEach(async function () {
            await this.challenge.set_mock_passed(false)
            await this.registry.resolveChallenge(itemId, { from: rando })
          })

          it('transfers the reward to the registry', async function () {
            expect(await this.token.balanceOf(this.registry.address)).to.be.bignumber.equal(mockChallengeReward)
          })

          it('adds the reward to the item owner\'s stake', async function () {
            expect(await this.registry.ownerStakes(itemId)).to.be.bignumber.equal(mockChallengeReward)
          })

          it('does not change the item owner', async function () {
            expect(await this.registry.owners(itemId)).to.equal(owner)
          })

          it('does not delete the item', async function () {
            expect(await this.registry.exists(itemId)).to.be.true
          })

          it('unlocks the item', async function () {
            expect(await this.registry.isLocked(itemId)).to.be.false
          })

          shouldCloseChallenge()
          shouldDeleteChallenge()
          shouldTransferRewardFromChallenge()
        })

        function shouldCloseChallenge () {
          it('closes the challenge', async function () {
            expect(await this.challenge.isClosed()).to.be.true
          })
        }

        function shouldDeleteChallenge () {
          it('deletes the challenge from the registry', async function () {
            expect(await this.registry.challenges(itemId)).to.equal(ZERO_ADDRESS)
          })
        }

        function shouldTransferRewardFromChallenge () {
          it('transfers reward from the challenge', async function () {
            expect(await this.token.balanceOf(this.challenge.address)).to.be.bignumber.equal(minStake * 2 - mockChallengeReward)
          })
        }
      })
    })
  })
}

module.exports = {
  shouldBehaveLikeTokenCuratedRegistry
}
