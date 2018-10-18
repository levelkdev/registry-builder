pragma solidity ^0.4.24;

interface IChallenge {
  // returns true if the challenge has ended
  function close() public;

  // returns true if the challenge has passed
  // reverts if challenge has not been closed
  function passed() public view returns (bool);

  // returns the amount of tokens to transfer back to the registry contract
  // after the challenge has ended, to be distributed as a reward for applicant/challenger
  function reward() public view returns (uint rewardAmount);

  // returns the address of the challenger
  function challenger() view returns (address);
}
