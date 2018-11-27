pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "./BasicRegistry.sol";

/**
 * @title TimelockableItemRegistry
 * @dev A registry that allows items to be locked from removal.
 */
contract TimelockableItemRegistry is Initializable, BasicRegistry {

  // maps item id to a time when the item will be unlocked.
  mapping(bytes32 => uint) public unlockTimes;

  /**
   * @dev Overrides BasicRegistry.remove(), deletes item owner state.
   * @param id The item to remove from the registry.
   */
  function remove(bytes32 id) public {
    require(!isLocked(id));
    delete unlockTimes[id];
    super.remove(id);
  }

  /**
   * @dev Checks if an item is locked, reverts if the item does not exist.
   * @param id The item to check.
   * @return A bool indicating whether the item is locked.
   */
  function isLocked(bytes32 id) public view returns (bool) {
    require(_exists(id));
    return _isLocked(id);
  }

  /**
   * @dev Internal function to check if an item is locked.
   * @param id The item to check.
   * @return A bool indicating whether the item is locked.
   */
  function _isLocked(bytes32 id) internal view returns (bool) {
    return unlockTimes[id] > now;
  }
}
