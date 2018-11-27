pragma solidity ^0.4.24;

/**
 * @title IRegistry
 * @dev An interface for registries.
 */
interface IRegistry {
  function add(bytes32 id) public;
  function remove(bytes32 id) public;
  function exists(bytes32 id) public view returns (bool item);
}
