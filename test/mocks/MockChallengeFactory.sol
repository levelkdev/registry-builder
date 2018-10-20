pragma solidity ^0.4.24;

import '../../contracts/Challenge/IChallengeFactory.sol';
import './MockChallenge.sol';

contract MockChallengeFactory is IChallengeFactory {

  address public registry;
  address public challenger;
  address public itemOwner;
  uint public reward;

  constructor (uint _reward) public {
    reward = _reward;
  }

  function createChallenge(address _registry, address _challenger, address _itemOwner) returns (address challenge) {
    registry = _registry;
    challenger = _challenger;
    itemOwner = _itemOwner;
    MockChallenge mockChallenge = new MockChallenge();
    mockChallenge.set_mock_challenger(_challenger);
    mockChallenge.set_mock_reward(reward);
    return address(mockChallenge);
  }

}
