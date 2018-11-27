pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "./IRegistry.sol";

/**
 * @title BasicRegistry
 * @dev A simple implementation of IRegistry, allows any address to add/remove items
 */
contract BasicRegistry is Initializable, IRegistry {

    mapping(bytes32 => bool) items;

    event ItemAdded(bytes32 id);

    event ItemRemoved(bytes32 id);

    /**
     * @dev Adds an item to the registry.
     * @param id The item to add to the registry, must be unique.
     */
    function add(bytes32 id) public {
        require(!_exists(id));
        items[id] = true;
        ItemAdded(id);
    }

    /**
     * @dev Removes an item from the registry, reverts if the item does not exist.
     * @param id The item to remove from the registry.
     */
    function remove(bytes32 id) public {
        require(_exists(id));
        _remove(id);
    }

    /**
     * @dev Checks if an item exists in the registry.
     * @param id The item to check.
     * @return A bool indicating whether the item exists.
     */
    function exists(bytes32 id) public view returns (bool) {
        return _exists(id);
    }

    /**
     * @dev Internal function to check if an item exists in the registry.
     * @param id The item to check.
     * @return A bool indicating whether the item exists.
     */
    function _exists(bytes32 id) internal view returns (bool) {
        return items[id];
    }

    /**
     * @dev Internal function to remove an item from the registry.
     * @param id The item to remove from the registry.
     */
    function _remove(bytes32 id) internal {
        items[id] = false;
        ItemRemoved(id);
    }
}
