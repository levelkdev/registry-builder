pragma solidity ^0.4.24;

/**
 * @title IRegistry
 * @dev An interface for registries.
 */
interface IRegistry {
  function add(bytes32 data) public;
  function remove(bytes32 data) public;
  function exists(bytes32 data) public view returns (bool item);
}
