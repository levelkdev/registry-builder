pragma solidity ^0.4.24;

interface IRegistry {
  function add(bytes32 data) public returns (bytes32 id);
  function remove(bytes32 id) public;
  function getItem(bytes32 id) public view returns (bytes32 data);
}
