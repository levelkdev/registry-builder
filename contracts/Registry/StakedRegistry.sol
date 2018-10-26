pragma solidity ^0.4.24;

import './OwnedItemRegistry.sol';
import 'openzeppelin-zos/contracts/math/SafeMath.sol';
import 'openzeppelin-zos/contracts/token/ERC20/ERC20.sol';

// handles token stake for owned items. Requires a minimum stake. Allows
// the owner to increase or decrease stake, as long as it remains above
// the minimum stake.
contract StakedRegistry is OwnedItemRegistry {
  using SafeMath for uint;

  event NewStake(bytes32 indexed itemData, uint totalStake);
  event StakeIncreased(bytes32 indexed itemData, uint totalStake, uint increaseAmount);
  event StakeDecreased(bytes32 indexed itemData, uint totalStake, uint decreaseAmount);

  ERC20 public token;
  uint public minStake;      // minimum required amount of tokens to add an item

  mapping(bytes32 => uint) public ownerStakes;

  constructor(ERC20 _token, uint _minStake) public {
    require(address(_token) != 0x0);
    token = _token;
    minStake = _minStake;
  }

  function add(bytes32 data) public {
    require(token.transferFrom(msg.sender, this, minStake));
    super.add(data);
    ownerStakes[data] = minStake;
    emit NewStake(data, ownerStakes[data]);
  }

  function remove(bytes32 data) public {
    require(token.transfer(msg.sender, ownerStakes[data]));
    delete ownerStakes[data];
    super.remove(data);
  }

  function increaseStake(bytes32 data, uint stakeAmount) public onlyItemOwner(data) {
    require(token.transferFrom(msg.sender, this, stakeAmount));
    ownerStakes[data] = ownerStakes[data].add(stakeAmount);
    emit StakeIncreased(data, ownerStakes[data], stakeAmount);
  }

  function decreaseStake(bytes32 data, uint stakeAmount) public onlyItemOwner(data) {
    require(ownerStakes[data].sub(stakeAmount) > minStake);
    require(token.transfer(msg.sender, stakeAmount));
    ownerStakes[data] = ownerStakes[data].sub(stakeAmount);
    emit StakeDecreased(data, ownerStakes[data], stakeAmount);
  }

}
