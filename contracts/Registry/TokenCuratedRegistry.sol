pragma solidity ^0.4.24;

import './LockableItemRegistry.sol';
import './StakedRegistry.sol';
import '../Challenge/IChallengeFactory.sol';
import '../Challenge/IChallenge.sol';

contract TokenCuratedRegistry is StakedRegistry, LockableItemRegistry {
  uint applicationPeriod;
  IChallengeFactory public challengeFactory;
  mapping(bytes32 => IChallenge) public challenges;
  
  constructor(ERC20 _token, uint _minStake, uint _applicationPeriod, IChallengeFactory _challengeFactory)
  StakedRegistry(_token, _minStake)
  public {
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
  // requires that this is called by the item owner. LockableItemRegistry.remove requires
  // that the item is not locked.
  function remove(bytes32 id) public {
    require(!challengeActive(id) && !challengePassed(id));
    delete challenges[id];
    super.remove(id);
  }

  // Creates a new challenge for an item.
  // Requires that the item exists, and that there is no existing challenge for the item.
  // Requires msg.sender (the challenger) to match the owner's stake by transferring to
  // this contract. The challenger's and owner's stake is transferred to the newly created
  // challenge contract.
  function challenge(bytes32 id) public {
    require(exists(id) && !challengeExists(id));
    require(token.transferFrom(msg.sender, this, minStake));
    address challenge = challengeFactory.create(this, msg.sender, owners[id]);
    require(token.transfer(challenge, minStake.mul(2)));
  }

  // Handles transfer of reward after a challenge has ended. Requires that there
  // is an ended challenge for the item.
  function resolveChallenge(bytes32 id) public {
    require(challengeEnded(id));
    if (challengePassed(id)) {
      // if the challenge passed, reward the challenger (via token.transfer) and remove
      // the item.
      require(token.transfer(challenges[id].challenger(), _redeemReward(id)));
      delete ownerStakes[id];
      super.remove(id);
    } else {
      // if the challenge failed, reward the applicant (by adding to their staked balance)
      ownerStakes[id] = ownerStakes[id].add(_redeemReward(id)).sub(minStake);
    }
    delete unlockTimes[id];
    delete challenges[id];
  }

  // Returns true if the item exists and is not locked. We know that locked items are in
  // the application phase, because the unlock time is set to now + applicationPeriod when
  // items are added. Also, unlock time is set to 0 if an item is challenged and the
  // challenge fails.
  function inApplicationPhase(bytes32 id) public view returns (bool) {
    return exists(id) && !isLocked(id);
  }

  function challengeActive(bytes32 id) public view returns (bool) {
    return exists(id) && challengeExists(id) && !challenges[id].ended();
  }

  function challengePassed(bytes32 id) public view returns (bool) {
    return challengeEnded(id) && challenges[id].passed();
  }

  function challengeEnded(bytes32 id) public view returns (bool) {
    return exists(id) && challengeExists(id) && challenges[id].ended();
  }

  function challengeExists(bytes32 id) public view returns (bool) {
    return address(challenges[id]) != 0x0;
  }

  // internals...

  function _redeemReward(bytes32 id) internal returns (uint reward) {
    reward = challenges[id].reward();
    require(token.transferFrom(challenges[id], this, reward));
  }
}
