pragma solidity ^0.4.24;

interface IChallenge {
  // returns true if the challenge has ended
  function ended() view returns(bool);

  // returns true if the challenge has passed
  function passed() view returns (bool);

  // returns the amount of tokens to transfer back to the registry contract
  // after the challenge has eneded, to be distributed as a reward for applicant/challenger
  function reward() view returns (uint);

  // returns the address of the challenger
  function challenger() view returns (address);
}
