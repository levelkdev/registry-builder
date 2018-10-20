const { shouldBehaveLikeBasicRegistry } = require('./BasicRegistry.behavior')

const BasicRegistry = artifacts.require('BasicRegistry')

contract('BasicRegistry', function () {

  beforeEach(async function () {
    this.registry = await BasicRegistry.new()
  })

  shouldBehaveLikeBasicRegistry()

})
