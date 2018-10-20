pragma solidity ^0.4.24;

import 'openzeppelin-zos/contracts/token/ERC20/ERC20.sol';
import '../../contracts/Challenge/IChallenge.sol';

contract MockChallenge is IChallenge {

  bool public isClosed;

  bool mock_passed;
  uint mock_reward;
  address mock_challenger;

  function set_mock_passed (bool _val) {
    mock_passed = _val;
  }

  function set_mock_reward (uint _val) {
    mock_reward = _val;
  }

  function set_mock_challenger (address _val) {
    mock_challenger = _val;
  }

  function close() public {
    isClosed = true;
  }

  function passed() public view returns (bool) {
    return mock_passed;
  }

  function reward() public view returns (uint) {
    return mock_reward;
  }

  function challenger() view returns (address) {
    return mock_challenger;
  }

  function approveRewardTransfer (ERC20 token, address registry) public {
    token.approve(registry, mock_reward);
  }

}
