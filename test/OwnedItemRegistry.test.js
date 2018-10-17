const { shouldBehaveLikeBasicRegistry } = require('./BasicRegistry.behavior')

const OwnedItemRegistry = artifacts.require('OwnedItemRegistry')

contract('OwnedItemRegistry', function () {
  
  beforeEach(async function () {
    this.registry = await OwnedItemRegistry.new()
  })

  shouldBehaveLikeBasicRegistry()

})