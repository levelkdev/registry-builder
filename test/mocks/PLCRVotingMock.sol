pragma solidity ^0.4.24;

contract PLCRVotingMock {
  address public token;
  uint public pollNonce;
  bool mock_isPassed;
  bool mock_pollEnded;
  uint mock_getTotalNumberOfTokensForWinningOption;
  uint mock_getNumPassingTokens;

  constructor(address _token) public {
    token = _token;
    pollNonce = 0;
  }

  // =========================
  // startPoll Mock
  // =========================
  function startPoll (uint voteQuorum,
    uint commitStageLength,
    uint revealStageLength
  ) public returns (uint) {
    pollNonce += 1;
    return pollNonce;
  }


  // =========================
  // pollEnded Mock
  // =========================
  function set_mock_pollEnded(bool ended) public {
    mock_pollEnded = ended;
  }

  function pollEnded(uint pollID) constant public returns (bool) {
    return mock_pollEnded;
  }



  // =========================
  // isPassed Mock
  // =========================
  function set_mock_isPassed(bool passed) public {
    mock_isPassed = passed;
  }

  function isPassed(uint pollID) public view returns (bool) {
    return mock_isPassed;
  }



  // ============================================
  // getTotalNumberOfTokensForWinningOption Mock
  // ============================================
  function set_mock_getTotalNumberOfTokensForWinningOption(uint winningTokenAmount) public {
    mock_getTotalNumberOfTokensForWinningOption = winningTokenAmount;
  }

  function getTotalNumberOfTokensForWinningOption(uint pollID) public returns (uint) {
    return mock_getTotalNumberOfTokensForWinningOption;
  }



  // ===========================
  // getNumPassingTokens Mock
  // ===========================
  function set_mock_getNumPassingTokens(uint numPassingTokens) public {
    mock_getNumPassingTokens = numPassingTokens;
  }

  function getNumPassingTokens(address voter, uint pollID) public returns (uint) {
    return mock_getNumPassingTokens;
  }

}
