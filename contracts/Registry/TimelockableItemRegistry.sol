pragma solidity ^0.4.24;

import './BasicRegistry.sol';

// provides a mapping of unlock times for items. Only allows
// item removal when the unlock time has been exceeded.
contract TimelockableItemRegistry is BasicRegistry {
  mapping(bytes32 => uint) public unlockTimes;

  function remove(bytes32 id) public {
    require(!isLocked(id));
    delete unlockTimes[id];
    super.remove(id);
  }

  function isLocked(bytes32 id) public view returns (bool) {
    require(exists(id));
    return unlockTimes[id] > now;
  }
}
