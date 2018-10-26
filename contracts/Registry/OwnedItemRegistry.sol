pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "./BasicRegistry.sol";

/**
 * @title OwnedItemRegistry
 * @dev A registry where items are only removable by an item owner.
 */
contract OwnedItemRegistry is Initializable, BasicRegistry {

  // maps item data to owner address.
  mapping(bytes32 => address) public owners;

  /**
   * @dev Modifier to make function callable only by item owner.
   * @param data The item to require ownership for.
   */
  modifier onlyItemOwner(bytes32 data) {
    require(owners[data] == msg.sender);
    _;
  }

  /**
   * @dev Overrides BasicRegistry.add(), sets msg.sender as item owner.
   * @param data The item to add to the registry.
   */
  function add(bytes32 data) public {
    super.add(data);
    owners[data] = msg.sender;
  }

  /**
   * @dev Overrides BasicRegistry.remove(), deletes item owner state.
   * @param data The item to remove from the registry.
   */
  function remove(bytes32 data) public onlyItemOwner(data) {
    delete owners[data];
    super.remove(data);
  }
}
