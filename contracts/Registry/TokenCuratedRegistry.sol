pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "./TimelockableItemRegistry.sol";
import "./StakedRegistry.sol";
import "../Challenge/IChallengeFactory.sol";
import "../Challenge/IChallenge.sol";

/**
 * @title TokenCuratedRegistry
 * @dev A registry with tokenized goverence of item addition and removal.
 * Based on https://github.com/skmgoldin/tcr
 */
contract TokenCuratedRegistry is Initializable, StakedRegistry, TimelockableItemRegistry {

  // amount of time to lock new items in the application phase.
  uint public applicationPeriod;

  // contract used to create new challenges.
  IChallengeFactory public challengeFactory;

  // maps item id to challenge contract addresses.
  mapping(bytes32 => IChallenge) public challenges;

  event Application(bytes32 indexed itemid, address indexed itemOwner, uint applicationEndDate);

  event ItemRejected(bytes32 indexed itemid);

  event ChallengeSucceeded(bytes32 indexed itemid, address challenge);

  event ChallengeFailed(bytes32 indexed itemid, address challenge);

  event ChallengeInitiated(bytes32 indexed itemid, address challenge, address challenger);

  function initialize(
    ERC20 _token,
    uint _minStake,
    uint _applicationPeriod,
    IChallengeFactory _challengeFactory
  )
    initializer
    public
  {
    require(address(_challengeFactory) != 0x0);
    applicationPeriod = _applicationPeriod;
    challengeFactory = _challengeFactory;
    StakedRegistry.initialize(_token, _minStake);
  }

  /**
   * @dev Overrides StakedRegistry.add(), sets unlock time to end of application period.
   * @param id The item to add to the registry.
   */
  function add(bytes32 id) public {
    super.add(id);
    unlockTimes[id] = now.add(applicationPeriod);
    emit Application(id, msg.sender, unlockTimes[id]);
  }

  /**
   * @dev Overrides StakedRegistry.remove(), requires that there is no challenge for the item.
   * @param id The item to remove from the registry.
   */
  function remove(bytes32 id) public {
    require(!challengeExists(id));
    super.remove(id);
  }

  /**
   * @dev Creates a new challenge for an item, sets msg.sender as the challenger. Requires the
   * challenger to match the item owner's stake.
   * @param id The item to challenge.
   */
  function challenge(bytes32 id) public {
    require(!challengeExists(id));
    require(token.transferFrom(msg.sender, this, minStake));
    challenges[id] = IChallenge(challengeFactory.createChallenge(this, msg.sender, owners[id]));

    uint challengeFunds = challenges[id].fundsRequired();
    require(challengeFunds <= minStake);
    require(token.approve(challenges[id], challengeFunds));

    emit ChallengeInitiated(id, challenges[id], msg.sender);
  }

  /**
   * @dev Resolves a challenge by allocating reward tokens to the winner, closing the challenge
   * contract, and deleting challenge state.
   * @param id The item to challenge.
   */
  function resolveChallenge(bytes32 id) public {
    require(challengeExists(id));

    if(!challenges[id].isClosed()) {
      challenges[id].close();
    }

    uint reward = challenges[id].winnerReward();
    if (challenges[id].passed()) {
      // if the challenge passed, reward the challenger (via token.transfer), then remove
      // the item and all state related to it
      require(token.transfer(challenges[id].challenger(), reward));
      emit ChallengeSucceeded(id, challenges[id]);
      _reject(id);
    } else {
      // if the challenge failed, reward the applicant (by adding to their staked balance)
      ownerStakes[id] = ownerStakes[id].add(reward).sub(minStake);
      emit ChallengeFailed(id, challenges[id]);
      delete unlockTimes[id];
      delete challenges[id];
    }
  }

  /**
   * @dev Checks if an item is in the application phase, reverts if the item does not exist.
   * @return A bool indicating whether the item is in the application phase.
   */
  function inApplicationPhase(bytes32 id) public view returns (bool) {
    return isLocked(id);
  }

  /**
   * @dev Checks if a challenge exists for an item, reverts if the item does not exist.
   * @param id The item to check for an existing challenge.
   * @return A bool indicating whether a challenge exists for the item.
   */
  function challengeExists(bytes32 id) public view returns (bool) {
    require(_exists(id));
    return address(challenges[id]) != 0x0;
  }

  /**
   * @dev Overrides BasicRegistry.exists(), adds logic to check that the item is not locked in
   * the application phase.
   * @param id The item to check for existence on the registry.
   * @return A bool indicating whether the item exists on the registry.
   */
  function exists(bytes32 id) public view returns (bool) {
    return _exists(id) && !_isLocked(id);
  }

  /**
   * @dev Internal function to reject an item from the registry by deleting all item state.
   * @param id The item to reject.
   */
  function _reject(bytes32 id) internal {
    ownerStakes[id] = 0;
    delete owners[id];
    delete unlockTimes[id];
    delete challenges[id];
    _remove(id);
    emit ItemRejected(id);
  }
}
