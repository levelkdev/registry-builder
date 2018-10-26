pragma solidity ^0.4.24;

/**
 * @title IChallenge
 * @dev An interface for challenges.
 */
interface IChallenge {
  // returns the address of the challenger.
  function challenger() view returns (address);

  // closes the challenge.
  function close() public;

  // should return `true` if close() has been called.
  function isClosed() public view returns (bool);

  // indicates whether the challenge has passed.
  function passed() public view returns (bool);

  // returns the amount of tokens the challenge needs to reward participants.
  function fundsRequired() public view returns (uint);

  // returns amount of tokens that should be allocated to challenge winner
  function winnerReward() public view returns (uint);
}
