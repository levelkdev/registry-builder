pragma solidity ^0.4.24;

import './TestToken.sol';

contract RegistryMock {
  TestToken public token;

  constructor(address _token) public {
    token = TestToken(_token);
  }

  function mock_approveTokenToChallenge(address challenge, uint amount) public {
    token.approve(challenge, amount);
  }

}
