pragma solidity ^0.4.24;

import '../../contracts/Registry/TimelockableItemRegistry.sol';

contract MockTimelockableItemRegistry is TimelockableItemRegistry {

  function setUnlockTime(bytes32 id, uint unlockTime) public {
    unlockTimes[id] = unlockTime;
  }

}
