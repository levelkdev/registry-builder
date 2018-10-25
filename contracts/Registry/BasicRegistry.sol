pragma solidity ^0.4.24;

import './IRegistry.sol';

/**
 * A generic registry app.
 * Inspired by Aragon Labs: https://github.com/aragonlabs/registry
 *
 * The registry has three simple operations: `add`, `remove` and `exists`.
 *
 * The registry itself is useless, but in combination with other apps to govern
 * the rules for who can add and remove entries in the registry, it becomes
 * a powerful building block (examples are token-curated registries and stake machines).
 */
contract BasicRegistry is IRegistry {
    // The items in the registry.
    mapping(bytes32 => bool) items;

    // Fired when an item is added to the registry.
    event ItemAdded(bytes32 data);
    // Fired when an item is removed from the registry.
    event ItemRemoved(bytes32 data);

    // @dev Adds an item to the registry.
    // @param data The item to add to the registry
    function add(bytes32 data) public {
        require(!exists(data));
        items[data] = true;
        ItemAdded(data);
    }

    // @dev Removes an item from the registry. Reverts if the item does not exist.
    // @param data The item data to remove
    function remove(bytes32 data) public {
        require(exists(data));
        _remove(data);
    }

    //  @dev Returns true if the given item data exists in the registry
    //  @param data The item data to check
    function exists(bytes32 data) public view returns (bool) {
        return items[data];
    }

    // @dev Internal function to remove an item from the registry.
    // @param data The item data to remove
    function _remove(bytes32 data) internal {
        items[data] = false;
        ItemRemoved(data);
    }
}
