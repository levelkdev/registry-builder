pragma solidity ^0.4.24;

/**
 * A generic registry app.
 * Inspired by Aragon Labs: https://github.com/aragonlabs/registry
 *
 * The registry has three simple operations: `add`, `remove` and `get`.
 *
 * The registry itself is useless, but in combination with other apps to govern
 * the rules for who can add and remove entries in the registry, it becomes
 * a powerful building block (examples are token-curated registries and stake machines).
 */
contract Registry {
    // The items in the registry.
    mapping(bytes32 => bytes32) items;

    // Fired when an item is added to the registry.
    event ItemAdded(bytes32 id);
    // Fired when an item is removed from the registry.
    event ItemRemoved(bytes32 id);

    // Add an item to the registry.
    // @param data The item to add to the registry
    function add(bytes32 data) public returns (bytes32 id) {
        id = keccak256(data);
        items[id] = data;
        ItemAdded(id);
    }

    // Remove an item from the registry.
    // @param id The ID of the item to remove
    function remove(bytes32 id) public {
        delete items[id];
        ItemRemoved(id);
    }

    //  Get an item from the registry.
    //  @param id The ID of the item to get
    function get(bytes32 id) public constant returns (bytes32) {
        return items[id];
    }
}
