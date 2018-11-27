pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "./BasicRegistry.sol";

/**
 * @title OwnedItemRegistry
 * @dev A registry where items are only removable by an item owner.
 */
contract OwnedItemRegistry is Initializable, BasicRegistry {

  // maps item id to owner address.
  mapping(bytes32 => address) public owners;

  /**
   * @dev Modifier to make function callable only by item owner.
   * @param id The item to require ownership for.
   */
  modifier onlyItemOwner(bytes32 id) {
    require(owners[id] == msg.sender);
    _;
  }

  /**
   * @dev Overrides BasicRegistry.add(), sets msg.sender as item owner.
   * @param id The item to add to the registry.
   */
  function add(bytes32 id) public {
    super.add(id);
    owners[id] = msg.sender;
  }

  /**
   * @dev Overrides BasicRegistry.remove(), deletes item owner state.
   * @param id The item to remove from the registry.
   */
  function remove(bytes32 id) public onlyItemOwner(id) {
    delete owners[id];
    super.remove(id);
  }
}
