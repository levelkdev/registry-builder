pragma solidity ^0.4.24;

import './StakedRegistry.sol';
import '../Challenge/IChallengeFactory.sol';
import '../Challenge/IChallenge.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract TokenCuratedRegistry is StakedRegistry {
  uint public applicationPeriod;
  IChallengeFactory public challengeFactory;

  modifier itemNotLockedInChallenge(bytes32 id) {
    require(!inChallengePhase(id));
    _;
  }

  modifier itemWhitelisted(bytes32 id) {
    require(!inApplicationPhase(id));
    _;
  }

  mapping(bytes32 => ItemCurationData) itemsCurationData;

  struct ItemCurationData {
    uint applicationExpiry;
    bool whiteListed;
    IChallenge challengeAddress;
    bool challengeResolved;
  }

  constructor (
    ERC20 _token,
    uint _minStake,
    uint _applicationPeriod,
    IChallengeFactory _challengeFactory
  ) public
    StakedRegistry(_token, _minStake)
  {
    applicationPeriod = _applicationPeriod;
    challengeFactory = _challengeFactory;
  }

  function add(bytes32 data) public returns (bytes32) {
    bytes32 id = keccak256(data);
    itemsCurationData[id] = ItemCurationData(now + applicationPeriod, false, IChallenge(0), false);
    return super.add(data);
  }

  function remove(bytes32 id) public itemWhitelisted(id) itemNotLockedInChallenge(id) {
    delete itemsCurationData[id];
    super.remove(id);
  }

  function whiteList(bytes32 id) public itemNotLockedInChallenge(id) {
    ItemCurationData storage itemCurationData = itemsCurationData[id]
    require(inApplicationPhase(id));
    require(itemCurationData.applicationExpiry < now);
    itemCurationData.whitelisted = true;
  }

  function resolveChallenge(bytes32 id) public {
    IChallenge challenge = itemsCurationData[id].challengeAddress;
    require(inChallengePhase(id));
    require(challenge.ended());

    if (challenge.passed()) {
      _redistributeItemStake(id);
      _rejectItem(id);
    } else {
      itemsCurationData[id].challengeResolved = true;
    }
  }

  function inChallengePhase(bytes32 id) public returns (bool) {
    ItemCurationData storage itemCurationData = itemsCurationData[id];

    if (itemCurationData.challengeAddress == IChallenge(0)) {
      return false;
    } else if (itemCurationData.challengeResolved) {
      return false;
    } else {
      return true;
    }
  }

  function inApplicationPhase(bytes32 id) public returns (bool) {
    itemsCurationData[id].whitelisted == false;
  }

  // INTERNAL FUNCTIONS

  function _rejectItem(bytes32 id) internal {
    delete items[id];
    delete itemsMetadata[id];
    delete itemsCurationData[id];
  }

  function _redistributeItemStake(bytes32 id) internal {
    // TODO: write functionality
  }
}
