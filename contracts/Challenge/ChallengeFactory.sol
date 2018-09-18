pragma solidity ^0.4.24;

interface ChallengeFactory {
  function createChallenge(address registry, address challenger, address itemOwner) returns (address challenge);
}
