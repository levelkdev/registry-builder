pragma solidity ^0.4.24;

interface IChallenge {
  function ended() view returns(bool);
  function passed() view returns (bool);

  // amount of tokens the Challenge will need to carry out operation
  function requestedTokenAmount() view returns (uint);

  // amount of tokens the Challenge will return to registry after conclusion (ie: winner reward)
  function returnTokenAmount() view returns (uint);
}
