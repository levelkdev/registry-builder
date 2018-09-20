pragma solidity ^0.4.24;

import './BasicRegistry.sol';

contract OwnedRegistry is BasicRegistry {

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  address owner;

  constructor(address _owner) public {
    owner = _owner;
  }

  function add(bytes32 data) public onlyOwner returns (bytes32 id) {
      return super.add(data);
  }

  function remove(bytes32 id) public onlyOwner {
      super.remove(id);
  }
}
