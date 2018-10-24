pragma solidity ^0.4.24;

import './BasicRegistry.sol';

// sets the msg.sender of the `add` transaction as the owner
// of the added item. Only allows the owner of the item to
// remove it.
contract OwnedItemRegistry is BasicRegistry {

  modifier onlyItemOwner(bytes32 id) {
    require(owners[id] == msg.sender);
    _;
  }

  mapping(bytes32 => address) public owners;

  function add(bytes32 data) public returns (bytes32 id) {
    id = super.add(data);
    owners[id] = msg.sender;
  }

  function remove(bytes32 id) public onlyItemOwner(id) {
    delete owners[id];
    super.remove(id);
  }
  
}
