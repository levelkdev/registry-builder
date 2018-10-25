pragma solidity ^0.4.24;

import './OwnedItemRegistry.sol';
import 'openzeppelin-zos/contracts/math/SafeMath.sol';
import 'openzeppelin-zos/contracts/token/ERC20/ERC20.sol';

// handles token stake for owned items. Requires a minimum stake. Allows
// the owner to increase or decrease stake, as long as it remains above
// the minimum stake.
contract StakedRegistry is OwnedItemRegistry {
  using SafeMath for uint;

  event NewStake(bytes32 indexed itemID, uint totalStake);
  event StakeIncreased(bytes32 indexed itemID, uint totalStake, uint increaseAmount);
  event StakeDecreased(bytes32 indexed itemID, uint totalStake, uint decreaseAmount);

  ERC20 public token;
  uint public minStake;      // minimum required amount of tokens to add an item

  mapping(bytes32 => uint) public ownerStakes;

  constructor(ERC20 _token, uint _minStake) public {
    require(address(_token) != 0x0);
    token = _token;
    minStake = _minStake;
  }

  function add(bytes32 data) public returns (bytes32 id) {
    require(token.transferFrom(msg.sender, this, minStake));
    id = super.add(data);
    ownerStakes[id] = minStake;
    emit NewStake(id, ownerStakes[id]);
  }

  function remove(bytes32 id) public {
    require(token.transfer(msg.sender, ownerStakes[id]));
    delete ownerStakes[id];
    super.remove(id);
  }

  function increaseStake(bytes32 id, uint stakeAmount) public onlyItemOwner(id) {
    require(token.transferFrom(msg.sender, this, stakeAmount));
    ownerStakes[id] = ownerStakes[id].add(stakeAmount);
    emit StakeIncreased(id, ownerStakes[id], stakeAmount);
  }

  function decreaseStake(bytes32 id, uint stakeAmount) public onlyItemOwner(id) {
    require(ownerStakes[id].sub(stakeAmount) > minStake);
    require(token.transfer(msg.sender, stakeAmount));
    ownerStakes[id] = ownerStakes[id].sub(stakeAmount);
    emit StakeDecreased(id, ownerStakes[id], stakeAmount);
  }

}
