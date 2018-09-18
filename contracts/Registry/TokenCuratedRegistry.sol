pragma solidity ^0.4.24;

import './StakedRegistry.sol';
import '../Challenge/ChallengeFactory.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract TokenCuratedRegistry is StakedRegistry {
  uint public applicationPeriod;
  ChallengeFactory public challengeFactory;

  modifier itemNotLockedInChallenge(bytes32 id) {
    require(!inChallengePhase(id));
    _;
  }

  mapping(bytes32 => ItemCurationData) itemsCurationData;

  struct ItemCurationData {
    uint applicationExpiry;
    bool whitelisted;
    address challengeAddress;
    bool challengeResolved;
  }

  constructor (
    ERC20 _token,
    uint _minStake,
    uint _applicationPeriod,
    ChallengeFactory _challengeFactory
  ) public
    StakedRegistry(_token, _minStake)
  {
    applicationPeriod = _applicationPeriod;
    challengeFactory = _challengeFactory;
  }

  function add(bytes32 data) public returns (bytes32) {
    bytes32 id = keccak256(data);
    itemsCurationData[id] = ItemCurationData(now + applicationPeriod, false, address(0), false);
    return super.add(data);
  }

  function remove(bytes32 id) public itemNotLockedInChallenge(id) {
    delete itemsCurationData[id];
    super.remove(id);
  }

  function inChallengePhase(bytes32 id) public returns (bool) {
    ItemCurationData storage itemCurationData = itemsCurationData[id];

    if (itemCurationData.challengeAddress == address(0)) {
      return false;
    } else if (itemCurationData.challengeResolved) {
      return false;
    } else {
      return true;
    }
  }
}
