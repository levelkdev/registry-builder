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

  // maps item data to challenge contract addresses.
  mapping(bytes32 => IChallenge) public challenges;

  event Application(bytes32 indexed itemData, address indexed itemOwner, uint applicationEndDate);

  event ItemRejected(bytes32 indexed itemData);

  event ChallengeSucceeded(bytes32 indexed itemData, address challenge);

  event ChallengeFailed(bytes32 indexed itemData, address challenge);

  event ChallengeInitiated(bytes32 indexed itemData, address challenge, address challenger);

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
   * @param data The item to add to the registry.
   */
  function add(bytes32 data) public {
    super.add(data);
    unlockTimes[data] = now.add(applicationPeriod);
    emit Application(data, msg.sender, unlockTimes[data]);
  }

  /**
   * @dev Overrides StakedRegistry.remove(), requires that there is no challenge for the item.
   * @param data The item to remove from the registry.
   */
  function remove(bytes32 data) public {
    require(!challengeExists(data));
    super.remove(data);
  }

  /**
   * @dev Creates a new challenge for an item, sets msg.sender as the challenger. Requires the
   * challenger to match the item owner's stake.
   * @param data The item to challenge.
   */
  function challenge(bytes32 data) public {
    require(!challengeExists(data));
    require(token.transferFrom(msg.sender, this, minStake));
    challenges[data] = IChallenge(challengeFactory.createChallenge(this, msg.sender, owners[data]));

    uint challengeFunds = challenges[data].fundsRequired();
    require(challengeFunds <= minStake);
    require(token.approve(challenges[data], challengeFunds));

    emit ChallengeInitiated(data, challenges[data], msg.sender);
  }

  /**
   * @dev Resolves a challenge by allocating reward tokens to the winner, closing the challenge
   * contract, and deleting challenge state.
   * @param data The item to challenge.
   */
  function resolveChallenge(bytes32 data) public {
    require(challengeExists(data));

    if(!challenges[data].isClosed()) {
      challenges[data].close();
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

  /**
   * @dev Checks if an item is in the application phase, reverts if the item does not exist.
   * @return A bool indicating whether the item is in the application phase.
   */
  function inApplicationPhase(bytes32 data) public view returns (bool) {
    return isLocked(data);
  }

  /**
   * @dev Checks if a challenge exists for an item, reverts if the item does not exist.
   * @param data The item to check for an existing challenge.
   * @return A bool indicating whether a challenge exists for the item.
   */
  function challengeExists(bytes32 data) public view returns (bool) {
    require(_exists(data));
    return address(challenges[data]) != 0x0;
  }

  /**
   * @dev Overrides BasicRegistry.exists(), adds logic to check that the item is not locked in
   * the application phase.
   * @param data The item to check for existence on the registry.
   * @return A bool indicating whether the item exists on the registry.
   */
  function exists(bytes32 data) public view returns (bool) {
    return _exists(data) && !_isLocked(data);
  }

  /**
   * @dev Internal function to reject an item from the registry by deleting all item state.
   * @param data The item to reject.
   */
  function _reject(bytes32 data) internal {
    ownerStakes[data] = 0;
    delete owners[data];
    delete unlockTimes[data];
    delete challenges[data];
    _remove(data);
    emit ItemRejected(data);
  }
}
