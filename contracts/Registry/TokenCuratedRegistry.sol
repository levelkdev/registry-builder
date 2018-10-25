pragma solidity ^0.4.24;

import './TimelockableItemRegistry.sol';
import './StakedRegistry.sol';
import '../Challenge/IChallengeFactory.sol';
import '../Challenge/IChallenge.sol';

contract TokenCuratedRegistry is StakedRegistry, TimelockableItemRegistry {

  event Application(bytes32 indexed itemData, address indexed itemOwner, uint applicationEndDate);
  event ItemRejected(bytes32 indexed itemData);
  event ChallengeSucceeded(bytes32 indexed itemData, address challenge);
  event ChallengeFailed(bytes32 indexed itemData, address challenge);
  event ChallengeInitiated(bytes32 indexed itemData, address challenge, address challenger);

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
  function add(bytes32 data) public {
    super.add(data);
    unlockTimes[data] = now.add(applicationPeriod);
    emit Application(data, msg.sender, unlockTimes[data]);
  }

  // Removes an item from the `items` mapping, and deletes challenge state. Requires that
  // there is not an active or passed challenge for this item. OwnedItemRegistry.remove
  // requires that this is called by the item owner. TimelockableItemRegistry.remove requires
  // that the item is not locked.
  function remove(bytes32 data) public {
    require(!challengeExists(data));
    super.remove(data);
  }

  // Creates a new challenge for an item.
  // Requires that the item exists, and that there is no existing challenge for the item.
  // Requires msg.sender (the challenger) to match the owner's stake by transferring to
  // this contract. The challenger's and owner's stake is transferred to the newly created
  // challenge contract.
  function challenge(bytes32 data) public {
    require(!challengeExists(data));
    require(token.transferFrom(msg.sender, this, minStake));
    challenges[data] = IChallenge(challengeFactory.createChallenge(this, msg.sender, owners[data]));

    uint challengeFunds = challenges[data].fundsRequired();
    require(challengeFunds <= minStake);
    require(token.approve(challenges[data], challengeFunds));

    emit ChallengeInitiated(data, challenges[data], msg.sender);
  }

  // Handles transfer of reward after a challenge has ended. Requires that there
  // is an ended challenge for the item.
  function resolveChallenge(bytes32 data) public {
    if(!challenges[data].isClosed()) {
      challenges[data].close(); // reverts if challenge cannot be closed yet
    }

    uint reward = challenges[data].winnerReward();
    if (challenges[data].passed()) {
      // if the challenge passed, reward the challenger (via token.transfer), then remove
      // the item and all state related to it
      require(token.transfer(challenges[data].challenger(), reward));
      emit ChallengeSucceeded(data, challenges[data]);
      _reject(data);
    } else {
      // if the challenge failed, reward the applicant (by adding to their staked balance)
      ownerStakes[data] = ownerStakes[data].add(reward).sub(minStake);
      emit ChallengeFailed(data, challenges[data]);
      delete unlockTimes[data];
      delete challenges[data];
    }
  }

  // Returns `true` if the item is locked, and `false` if the item is unlocked. We know that
  // locked items are in the application phase, because the unlock time is set to
  // now + applicationPeriod when items are added. Also, unlock time is set to 0 if an item
  // is challenged and the challenge fails.
  // Reverts if the item data does not exist.
  function inApplicationPhase(bytes32 data) public view returns (bool) {
    return isLocked(data);
  }

  // Returns `true` if a challenge exists for the given item data, and `false` if a challenge
  // does not exist for the given item data.
  // Reverts if the item data does not exist.
  function challengeExists(bytes32 data) public view returns (bool) {
    require(exists(data));
    return address(challenges[data]) != 0x0;
  }

  // Removes an item and all state related to the item
  function _reject(bytes32 data) internal {
    ownerStakes[data] = 0;
    delete owners[data];
    delete unlockTimes[data];
    delete challenges[data];
    _remove(data);
    emit ItemRejected(data);
  }
}
