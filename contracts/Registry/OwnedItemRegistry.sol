pragma solidity ^0.4.24;

import './BasicRegistry.sol';

// sets the msg.sender of the `add` transaction as the owner
// of the added item. Only allows the owner of the item to
// remove it.
contract OwnedItemRegistry is BasicRegistry {

  modifier onlyItemOwner(bytes32 data) {
    require(owners[data] == msg.sender);
    _;
  }

  mapping(bytes32 => address) public owners;

  function add(bytes32 data) public {
    super.add(data);
    owners[data] = msg.sender;
  }

  function remove(bytes32 data) public onlyItemOwner(data) {
    delete owners[data];
    super.remove(data);
  }
  
}
