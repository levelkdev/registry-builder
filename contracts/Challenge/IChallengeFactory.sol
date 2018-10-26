pragma solidity ^0.4.24;

/**
 * @title IChallengeFactory
 * @dev An interface for factory contracts that create challenges.
 */
interface IChallengeFactory {
  function createChallenge(address registry, address challenger, address itemOwner) returns (address challenge);
}
