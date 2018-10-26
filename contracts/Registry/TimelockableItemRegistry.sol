pragma solidity ^0.4.24;

import "./BasicRegistry.sol";

/**
 * @title TimelockableItemRegistry
 * @dev A registry that allows items to be locked from removal.
 */
contract TimelockableItemRegistry is BasicRegistry {

  // maps item data to a time when the item will be unlocked.
  mapping(bytes32 => uint) public unlockTimes;

  /**
   * @dev Overrides BasicRegistry.remove(), deletes item owner state.
   * @param data The item to remove from the registry.
   */
  function remove(bytes32 data) public {
    require(!isLocked(data));
    delete unlockTimes[data];
    super.remove(data);
  }

  /**
   * @dev Checks if an item is locked, reverts if the item does not exist.
   * @param data The item to check.
   * @return A bool indicating whether the item is locked.
   */
  function isLocked(bytes32 data) public view returns (bool) {
    require(_exists(data));
    return _isLocked(data);
  }

  /**
   * @dev Internal function to check if an item is locked.
   * @param data The item to check.
   * @return A bool indicating whether the item is locked.
   */
  function _isLocked(bytes32 data) internal view returns (bool) {
    return unlockTimes[data] > now;
  }
}
