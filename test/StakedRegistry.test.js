const { shouldFail } = require('lk-test-helpers')(web3)
const { shouldBehaveLikeOwnedItemRegistry } = require('./OwnedItemRegistry.behavior')
const parseListingTitle = require('./helpers/parseListingTitle')
const chai = require('chai')
const { expect } = chai.use(require('chai-bignumber')(web3.BigNumber))

const { data: itemData, hash: itemId } = parseListingTitle('listing 001')

const StakedRegistry = artifacts.require('MockStakedRegistry')
const TestToken = artifacts.require('TestToken')

contract('StakedRegistry', function (accounts) {

  const [owner, owner2, rando] = accounts
  const initialBalance = 100 * 10 ** 18

  beforeEach(async function () {
    this.minStake = 10 * 10 ** 18
    this.token = await TestToken.new(
      [owner, owner2, rando],
      initialBalance
    )
    this.registry = await StakedRegistry.new(this.token.address, this.minStake)
    await this.token.approve(this.registry.address, this.minStake, { from: owner })
  })

  shouldBehaveLikeOwnedItemRegistry(accounts)

  describe('add()', function () {
    describe('when token transfer from sender succeeds', function () {
      beforeEach(async function () {
        await this.registry.add(itemData, { from: owner })
      })

      it('transfers stake from the owner', async function () {
        expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(initialBalance - this.minStake)
      })

      it('transfers stake to the registry', async function () {
        expect(await this.token.balanceOf(this.registry.address)).to.be.bignumber.equal(this.minStake)
      })
    })

    describe('when token transfer from sender fails', function () {
      it('reverts', async function () {
        await shouldFail.reverting(this.registry.add(itemData, { from: owner2 }))
      })
    })
  })

  describe('remove()', function () {
    beforeEach(async function () {
      await this.registry.add(itemData, { from: owner })
    })

    describe('when token transfer succeeds', function () {
      beforeEach(async function () {
        await this.registry.remove(itemId, { from: owner })
      })

      it('transfers stake to the owner', async function () {
        expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(initialBalance)
      })

      it('transfers stake from the registry', async function () {
        expect(await this.token.balanceOf(this.registry.address)).to.be.bignumber.equal(0)
      })
    })

    describe('when owner stake is 0', function () {
      beforeEach(async function () {
        await this.registry.setOwnerStake(itemId, 0)
        await this.registry.remove(itemId, { from: owner })
      })

      it('transfers 0 stake to the owner', async function () {
        expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(initialBalance - this.minStake)
      })

      it('transfers 0 stake from the registry', async function () {
        expect(await this.token.balanceOf(this.registry.address)).to.be.bignumber.equal(this.minStake)
      })
    })
  })

  describe('increaseStake()', function () {

    beforeEach(async function () {
      this.additionalStake = 5 * 10 ** 18
      this.totalStake = this.minStake + this.additionalStake
      this.expectedOwnerBalance = initialBalance - this.totalStake
      await this.registry.add(itemData, { from: owner })
    })

    describe('when executed by item owner', function () {

      describe('and token transfer is successful', function () {
        beforeEach(async function () {
          await this.token.approve(this.registry.address, this.additionalStake, { from: owner })
          await this.registry.increaseStake(itemId, this.additionalStake, { from: owner })
        })

        it('transfers additional stake amount from the sender', async function () {
          expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(this.expectedOwnerBalance)
        })
        
        it('transfers additional stake amount to the registry', async function () {
          expect(await this.token.balanceOf(this.registry.address)).to.be.bignumber.equal(this.totalStake)
        })
      })

      describe('and token transfer fails', function () {
        it('reverts', async function () {
          await shouldFail.reverting(this.registry.increaseStake(itemId, 1000, { from: owner }))
        })
      })
    })

    describe('when not executed by item owner', function () {
      it('reverts', async function () {
        await this.token.approve(this.registry.address, this.additionalStake, { from: rando })
        await shouldFail.reverting(this.registry.increaseStake(itemId, this.additionalStake, { from: rando }))
      })
    })

  })

  describe('decreaseStake()', function () {

    beforeEach(async function () {
      this.additionalStake = 5 * 10 ** 18
      this.decreaseAmount = 2 * 10 ** 18
      this.totalStake = this.minStake + this.additionalStake - this.decreaseAmount
      this.expectedOwnerBalance = initialBalance - this.totalStake
      await this.registry.add(itemData, { from: owner })
      await this.token.approve(this.registry.address, this.additionalStake, { from: owner })
      await this.registry.increaseStake(itemId, this.additionalStake, { from: owner })
    })

    describe('when executed by item owner', function () {
      describe('and decreased to a balance that would exceed the minimum stake', function () {
        beforeEach(async function () {
          await this.registry.decreaseStake(itemId, this.decreaseAmount, { from: owner })
        })

        it('transfers stake to the owner', async function () {
          expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(this.expectedOwnerBalance)
        })

        it('transfers stake from the registry', async function () {
          expect(await this.token.balanceOf(this.registry.address)).to.be.bignumber.equal(this.totalStake)
        })
      })

      describe('and decreased to a balance that would not exceed the minimum stake', function () {
        it('reverts', async function () {
          await shouldFail.reverting(this.registry.decreaseStake(itemId, this.additionalStake + 1 * 10 ** 18, { from: owner }))
        })
      })
    })

    describe('when not exected by item owner', function () {
      it('reverts', async function () {
        await shouldFail.reverting(this.registry.decreaseStake(itemId, this.decreaseAmount, { from: rando }))
      })
    })

  })

})