pragma solidity ^0.4.24;

import './BasicRegistry.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract StakedRegistry is BasicRegistry {
  ERC20 token;
  uint minStake; // the minimum required amount of tokens staked

  modifier onlyItemOwner(bytes32 id) {
    require(itemsMetadata[id].owner == msg.sender);
    _;
  }

  mapping(bytes32 => ItemMetadata) itemsMetadata;

  struct ItemMetadata {
    address owner;
    uint stakedTokens;
  }

  constructor(ERC20 _token, uint _minStake) public {
    token = _token;
    minStake = _minStake;
  }

  function add(bytes32 data) public returns (bytes32) {
    require(token.transferFrom(msg.sender, this, minStake));
    bytes32 id = keccak256(data);
    itemsMetadata[id] = ItemMetadata(msg.sender, minStake);
    return super.add(data);
  }

  function remove(bytes32 id) public onlyItemOwner(id) {
    uint stakedAmount = itemsMetadata[id].stakedTokens;
    token.transfer(msg.sender, stakedAmount);
    delete itemsMetadata[id];
    super.remove(id);
  }
}
