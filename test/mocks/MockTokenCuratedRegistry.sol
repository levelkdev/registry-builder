pragma solidity ^0.4.24;

import '../../contracts/Registry/TokenCuratedRegistry.sol';

contract MockTokenCuratedRegistry is TokenCuratedRegistry {

  constructor(ERC20 _token, uint _minStake, uint _applicationPeriod, IChallengeFactory _challengeFactory) public {
    TokenCuratedRegistry.initialize(_token, _minStake, _applicationPeriod, _challengeFactory);
  }

  function setUnlockTime(bytes32 id, uint unlockTime) public {
    unlockTimes[id] = unlockTime;
  }

  function setOwnerStake(bytes32 id, uint ownerStake) public {
    ownerStakes[id] = ownerStake;
  }

  function setChallenge(bytes32 id, IChallenge challenge) public {
    challenges[id] = challenge;
  }

}
