pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/math/SafeMath.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20.sol";
import "./OwnedItemRegistry.sol";

/**
 * @title StakedRegistry
 * @dev A registry that lets owners stake tokens on items.
 */
contract StakedRegistry is Initializable, OwnedItemRegistry {
  using SafeMath for uint;

  // token used for item stake.
  ERC20 public token;

  // minimum required amount of tokens to add an item.
  uint public minStake;

  // maps item id to owner stake amount.
  mapping(bytes32 => uint) public ownerStakes;

  event NewStake(bytes32 indexed itemid, uint totalStake);

  event StakeIncreased(bytes32 indexed itemid, uint totalStake, uint increaseAmount);

  event StakeDecreased(bytes32 indexed itemid, uint totalStake, uint decreaseAmount);

  function initialize(ERC20 _token, uint _minStake) initializer public {
    require(address(_token) != 0x0);
    token = _token;
    minStake = _minStake;
  }

  /**
   * @dev Overrides OwnedItemRegistry.add(), transfers tokens from owner, sets stake.
   * @param id The item to add to the registry.
   */
  function add(bytes32 id) public {
    require(token.transferFrom(msg.sender, this, minStake));
    super.add(id);
    ownerStakes[id] = minStake;
    emit NewStake(id, ownerStakes[id]);
  }

  /**
   * @dev Overrides BasicRegistry.add(), tranfers tokens to owner, deletes stake.
   * @param id The item to remove from the registry.
   */
  function remove(bytes32 id) public {
    require(token.transfer(msg.sender, ownerStakes[id]));
    delete ownerStakes[id];
    super.remove(id);
  }

  /**
   * @dev Increases stake for an item, only callable by item owner.
   * @param id The item to increase stake for.
   * @param stakeAmount The amount of tokens to add to the current stake.
   */
  function increaseStake(bytes32 id, uint stakeAmount) public onlyItemOwner(id) {
    require(token.transferFrom(msg.sender, this, stakeAmount));
    ownerStakes[id] = ownerStakes[id].add(stakeAmount);
    emit StakeIncreased(id, ownerStakes[id], stakeAmount);
  }

  /**
   * @dev Decreases stake for an item, only callable by item owner.
   * @param id The item to decrease stake for.
   * @param stakeAmount The amount of tokens to remove from the current stake.
   */
  function decreaseStake(bytes32 id, uint stakeAmount) public onlyItemOwner(id) {
    require(ownerStakes[id].sub(stakeAmount) > minStake);
    require(token.transfer(msg.sender, stakeAmount));
    ownerStakes[id] = ownerStakes[id].sub(stakeAmount);
    emit StakeDecreased(id, ownerStakes[id], stakeAmount);
  }
}
