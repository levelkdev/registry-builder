const { shouldBehaveLikeOwnedItemRegistry } = require('./OwnedItemRegistry.behavior')
const { shouldBehaveLikeBasicRegistry } = require('./BasicRegistry.behavior')

const OwnedItemRegistry = artifacts.require('OwnedItemRegistry')

contract('OwnedItemRegistry', function (accounts) {

  beforeEach(async function () {
    this.registry = await OwnedItemRegistry.new()
  })

  shouldBehaveLikeOwnedItemRegistry(accounts)
  shouldBehaveLikeBasicRegistry()

})