pragma solidity ^0.4.24;

import '../../contracts/Registry/TokenCuratedRegistry.sol';

contract MockTokenCuratedRegistry is TokenCuratedRegistry {

  constructor(ERC20 _token, uint _minStake, uint _applicationPeriod, IChallengeFactory _challengeFactory) public {
    TokenCuratedRegistry.initialize(_token, _minStake, _applicationPeriod, _challengeFactory);
  }

  function setUnlockTime(bytes32 data, uint unlockTime) public {
    unlockTimes[data] = unlockTime;
  }

  function setOwnerStake(bytes32 data, uint ownerStake) public {
    ownerStakes[data] = ownerStake;
  }

  function setChallenge(bytes32 data, IChallenge challenge) public {
    challenges[data] = challenge;
  }

}
