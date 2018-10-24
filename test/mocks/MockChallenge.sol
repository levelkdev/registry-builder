pragma solidity ^0.4.24;

import 'openzeppelin-zos/contracts/token/ERC20/ERC20.sol';
import '../../contracts/Challenge/IChallenge.sol';

contract MockChallenge is IChallenge {

  bool mock_isClosed;

  bool mock_passed;
  uint mock_winnerReward;
  address mock_challenger;
  uint mock_fundsRequired;

  function set_mock_passed (bool _val) {
    mock_passed = _val;
  }

  function set_mock_winnerReward (uint _val) {
    mock_winnerReward = _val;
  }

  function set_mock_challenger (address _val) {
    mock_challenger = _val;
  }

  function set_mock_fundsRequired(uint _val) {
    mock_fundsRequired = _val;
  }

  function close() public {
    mock_isClosed = true;
  }

  function isClosed() public view returns (bool) {
    return mock_isClosed;
  }

  function passed() public view returns (bool) {
    return mock_passed;
  }

  function winnerReward() public view returns (uint) {
    return mock_winnerReward;
  }

  function challenger() view returns (address) {
    return mock_challenger;
  }

  function fundsRequired() view returns (uint) {
    return mock_fundsRequired;
  }
}
