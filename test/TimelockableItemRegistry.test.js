const { shouldBehaveLikeTimelockableItemRegistry } = require('./TimelockableItemRegistry.behavior')
const { shouldBehaveLikeBasicRegistry } = require('./BasicRegistry.behavior')

const TimelockableItemRegistry = artifacts.require('MockTimelockableItemRegistry')

contract('TimelockableItemRegistry', function () {
  
  beforeEach(async function () {
    this.now = (await web3.eth.getBlock('latest')).timestamp
    this.registry = await TimelockableItemRegistry.new()
  })

  shouldBehaveLikeTimelockableItemRegistry()
  shouldBehaveLikeBasicRegistry()

})