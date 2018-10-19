pragma solidity ^0.4.24;

interface IChallengeFactory {
  function createChallenge(address registry, address challenger, address itemOwner) returns (address challenge);
}
