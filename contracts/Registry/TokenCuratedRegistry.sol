pragma solidity ^0.4.24;

import './TimelockableItemRegistry.sol';
import './StakedRegistry.sol';
import '../Challenge/IChallengeFactory.sol';
import '../Challenge/IChallenge.sol';

contract TokenCuratedRegistry is StakedRegistry, TimelockableItemRegistry {
  uint applicationPeriod;
  IChallengeFactory public challengeFactory;
  mapping(bytes32 => IChallenge) public challenges;

  constructor(ERC20 _token, uint _minStake, uint _applicationPeriod, IChallengeFactory _challengeFactory)
  StakedRegistry(_token, _minStake)
  public {
    require(address(_challengeFactory) != 0x0);
    applicationPeriod = _applicationPeriod;
    challengeFactory = _challengeFactory;
  }

  // Adds an item to the `items` mapping, transfers token stake from msg.sender, and locks
  // the item from removal until now + applicationPeriod.
  function add(bytes32 data) public returns (bytes32 id) {
    id = super.add(data);
    unlockTimes[id] = now.add(applicationPeriod);
  }

  // Removes an item from the `items` mapping, and deletes challenge state. Requires that
  // there is not an active or passed challenge for this item. OwnedItemRegistry.remove
  // requires that this is called by the item owner. TimelockableItemRegistry.remove requires
  // that the item is not locked.
  function remove(bytes32 id) public {
    if (challengeExists(id)) {
      require(!challenges[id].passed());
    }
    delete challenges[id];
    super.remove(id);
  }

  // Creates a new challenge for an item.
  // Requires that the item exists, and that there is no existing challenge for the item.
  // Requires msg.sender (the challenger) to match the owner's stake by transferring to
  // this contract. The challenger's and owner's stake is transferred to the newly created
  // challenge contract.
  function challenge(bytes32 id) public {
    require(!challengeExists(id));
    require(token.transferFrom(msg.sender, this, minStake));
    challenges[id] = IChallenge(challengeFactory.createChallenge(this, msg.sender, owners[id]));
    require(token.transfer(challenges[id], minStake.mul(2)));
  }

  // Handles transfer of reward after a challenge has ended. Requires that there
  // is an ended challenge for the item.
  function resolveChallenge(bytes32 id) public {
    challenges[id].close();
    uint reward = challenges[id].reward();
    require(token.transferFrom(challenges[id], this, reward));
    if (challenges[id].passed()) {
      // if the challenge passed, reward the challenger (via token.transfer) and remove
      // the item.
      require(token.transfer(challenges[id].challenger(), reward));
      ownerStakes[id] = 0;
      delete owners[id];
      _remove(id);
    } else {
      // if the challenge failed, reward the applicant (by adding to their staked balance)
      ownerStakes[id] = ownerStakes[id].add(reward).sub(minStake);
    }
    delete unlockTimes[id];
    delete challenges[id];
  }

  // Returns `true` if the item is locked, and `false` if the item is unlocked. We know that
  // locked items are in the application phase, because the unlock time is set to
  // now + applicationPeriod when items are added. Also, unlock time is set to 0 if an item
  // is challenged and the challenge fails.
  // Reverts if the item id does not exist.
  function inApplicationPhase(bytes32 id) public view returns (bool) {
    return isLocked(id);
  }

  // Returns `true` if a challenge exists for the given item id, and `false` if a challenge
  // does not exist for the given item id.
  // Reverts if the item id does not exist.
  function challengeExists(bytes32 id) public view returns (bool) {
    require(exists(id));
    return address(challenges[id]) != 0x0;
  }
}
