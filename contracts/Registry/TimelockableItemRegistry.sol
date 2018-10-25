pragma solidity ^0.4.24;

import './BasicRegistry.sol';

// provides a mapping of unlock times for items. Only allows
// item removal when the unlock time has been exceeded.
contract TimelockableItemRegistry is BasicRegistry {
  mapping(bytes32 => uint) public unlockTimes;

  function remove(bytes32 data) public {
    require(!isLocked(data));
    delete unlockTimes[data];
    super.remove(data);
  }

  function isLocked(bytes32 data) public view returns (bool) {
    require(exists(data));
    return unlockTimes[data] > now;
  }
}
