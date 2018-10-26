pragma solidity ^0.4.24;

import '../../contracts/Challenge/PLCRVotingChallengeFactory.sol';

contract MockPLCRVotingChallengeFactory is PLCRVotingChallengeFactory {
  constructor(
    uint challengerStake,
    address plcrVoting,
    uint commitStageLength,
    uint revealStageLength,
    uint voteQuorum,
    uint percentVoterReward
  ) public {
    PLCRVotingChallengeFactory.initialize(
      challengerStake,
      plcrVoting,
      commitStageLength,
      revealStageLength,
      voteQuorum,
      percentVoterReward
    );
  }
}
