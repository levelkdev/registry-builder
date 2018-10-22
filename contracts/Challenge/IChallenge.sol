pragma solidity ^0.4.24;

interface IChallenge {
  // returns the address of the challenger
  function challenger() view returns (address);

  // returns true if the challenge has ended
  function close() public;

  // returns true if the challenge has passed
  // reverts if challenge has not been closed
  function passed() public view returns (bool);

  // returns the amount of tokens the challenge must
  // obtain to carry out functionality
  function requiredFundsAmount() public view returns (uint);

  // returns amount to be rewarded to challenge winner
  function winnerReward() public view returns (uint);
}
