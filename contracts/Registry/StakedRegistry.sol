pragma solidity ^0.4.24;

import "openzeppelin-zos/contracts/math/SafeMath.sol";
import "openzeppelin-zos/contracts/token/ERC20/ERC20.sol";
import "./OwnedItemRegistry.sol";

/**
 * @title StakedRegistry
 * @dev A registry that lets owners stake tokens on items.
 */
contract StakedRegistry is OwnedItemRegistry {
  using SafeMath for uint;

  // token used for item stake.
  ERC20 public token;

  // minimum required amount of tokens to add an item.
  uint public minStake;

  // maps item data to owner stake amount.
  mapping(bytes32 => uint) public ownerStakes;

  event NewStake(bytes32 indexed itemData, uint totalStake);

  event StakeIncreased(bytes32 indexed itemData, uint totalStake, uint increaseAmount);

  event StakeDecreased(bytes32 indexed itemData, uint totalStake, uint decreaseAmount);

  constructor(ERC20 _token, uint _minStake) public {
    require(address(_token) != 0x0);
    token = _token;
    minStake = _minStake;
  }

  /**
   * @dev Overrides OwnedItemRegistry.add(), transfers tokens from owner, sets stake.
   * @param data The item to add to the registry.
   */
  function add(bytes32 data) public {
    require(token.transferFrom(msg.sender, this, minStake));
    super.add(data);
    ownerStakes[data] = minStake;
    emit NewStake(data, ownerStakes[data]);
  }

  /**
   * @dev Overrides BasicRegistry.add(), tranfers tokens to owner, deletes stake.
   * @param data The item to remove from the registry.
   */
  function remove(bytes32 data) public {
    require(token.transfer(msg.sender, ownerStakes[data]));
    delete ownerStakes[data];
    super.remove(data);
  }

  /**
   * @dev Increases stake for an item, only callable by item owner.
   * @param data The item to increase stake for.
   * @param stakeAmount The amount of tokens to add to the current stake.
   */
  function increaseStake(bytes32 data, uint stakeAmount) public onlyItemOwner(data) {
    require(token.transferFrom(msg.sender, this, stakeAmount));
    ownerStakes[data] = ownerStakes[data].add(stakeAmount);
    emit StakeIncreased(data, ownerStakes[data], stakeAmount);
  }

  /**
   * @dev Decreases stake for an item, only callable by item owner.
   * @param data The item to decrease stake for.
   * @param stakeAmount The amount of tokens to remove from the current stake.
   */
  function decreaseStake(bytes32 data, uint stakeAmount) public onlyItemOwner(data) {
    require(ownerStakes[data].sub(stakeAmount) > minStake);
    require(token.transfer(msg.sender, stakeAmount));
    ownerStakes[data] = ownerStakes[data].sub(stakeAmount);
    emit StakeDecreased(data, ownerStakes[data], stakeAmount);
  }
}
