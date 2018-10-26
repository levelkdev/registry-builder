pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "./IRegistry.sol";

/**
 * @title BasicRegistry
 * @dev A simple implementation of IRegistry, allows any address to add/remove items
 */
contract BasicRegistry is Initializable, IRegistry {

    mapping(bytes32 => bool) items;

    event ItemAdded(bytes32 data);

    event ItemRemoved(bytes32 data);

    /**
     * @dev Adds an item to the registry.
     * @param data The item to add to the registry, must be unique.
     */
    function add(bytes32 data) public {
        require(!_exists(data));
        items[data] = true;
        ItemAdded(data);
    }

    /**
     * @dev Removes an item from the registry, reverts if the item does not exist.
     * @param data The item to remove from the registry.
     */
    function remove(bytes32 data) public {
        require(_exists(data));
        _remove(data);
    }

    /**
     * @dev Checks if an item exists in the registry.
     * @param data The item to check.
     * @return A bool indicating whether the item exists.
     */
    function exists(bytes32 data) public view returns (bool) {
        return _exists(data);
    }

    /**
     * @dev Internal function to check if an item exists in the registry.
     * @param data The item to check.
     * @return A bool indicating whether the item exists.
     */
    function _exists(bytes32 data) internal view returns (bool) {
        return items[data];
    }

    /**
     * @dev Internal function to remove an item from the registry.
     * @param data The item to remove from the registry.
     */
    function _remove(bytes32 data) internal {
        items[data] = false;
        ItemRemoved(data);
    }
}
