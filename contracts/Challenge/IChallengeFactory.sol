pragma solidity ^0.4.24;

interface IChallengeFactory {
  function create(address registry, address challenger, address applicant) returns (address challenge);
}
