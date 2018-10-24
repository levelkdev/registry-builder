pragma solidity ^0.4.24;

interface IChallenge {
  // returns the address of the challenger
  function challenger() view returns (address);

  // returns true if the challenge has ended
  function close() public;

  // returns whether challenge has been officially closed
  function isClosed() public view returns (bool);

  // returns true if the challenge has passed
  // reverts if challenge has not been closed
  function passed() public view returns (bool);

  // @notice returns the amount of tokens the challenge must
  // obtain to carry out functionality
  function fundsRequired() public view returns (uint);

  // @dev returns amount to be rewarded to challenge winner
  function winnerReward() public view returns (uint);
}
