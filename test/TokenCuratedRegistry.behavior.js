const {
  shouldFail,
  increaseTime,
  constants
} = require('lk-test-helpers')(web3)
const parseListingTitle = require('./helpers/parseListingTitle')

const Challenge = artifacts.require('MockChallenge')

const { data: itemData, hash: itemId } = parseListingTitle('listing 001')
const { ZERO_BYTES32, ZERO_ADDRESS } = constants

function shouldBehaveLikeTokenCuratedRegistry (
  minStake,
  initialBalance,
  applicationPeriod,
  accounts
) {

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
        
        describe('and the challenge has ended and failed', function () {
          beforeEach(async function () {
            await this.challenge.set_mock_ended(true)
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

        describe('and the challenge has not ended', function () {
          it('reverts', async function () {
            await this.challenge.set_mock_ended(false)
            await this.challenge.set_mock_passed(false)
            await shouldFail.reverting(this.registry.remove(itemId))
          })
        })

        describe('and the challenge has passed', function () {
          it('reverts', async function () {
            await this.challenge.set_mock_ended(true)
            await this.challenge.set_mock_passed(true)
            await shouldFail.reverting(this.registry.remove(itemId))
          })
        })
      })
    })

  })

}

module.exports = {
  shouldBehaveLikeTokenCuratedRegistry
}
