const { shouldBehaveLikeOwnedItemRegistry } = require('./OwnedItemRegistry.behavior')

const OwnedItemRegistry = artifacts.require('OwnedItemRegistry')

contract('OwnedItemRegistry', function (accounts) {

  beforeEach(async function () {
    this.registry = await OwnedItemRegistry.new()
  })

  shouldBehaveLikeOwnedItemRegistry(accounts)

})