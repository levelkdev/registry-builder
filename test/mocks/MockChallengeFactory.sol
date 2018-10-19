pragma solidity ^0.4.24;

import '../../contracts/Challenge/IChallengeFactory.sol';
import './MockChallenge.sol';

contract MockChallengeFactory is IChallengeFactory {

  address public registry;
  address public challenger;
  address public itemOwner;

  function createChallenge(address _registry, address _challenger, address _itemOwner) returns (address challenge) {
    registry = _registry;
    challenger = _challenger;
    itemOwner = _itemOwner;
    return new MockChallenge();
  }

}
