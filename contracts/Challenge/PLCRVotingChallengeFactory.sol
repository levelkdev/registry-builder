pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "./IChallengeFactory.sol";
import "./PLCRVotingChallenge.sol";

/**
 * @title PLCRVotingChallengeFactory
 * @dev A challenge factory for creating PLCRVotingChallenge contracts.
 */
contract PLCRVotingChallengeFactory is Initializable, IChallengeFactory {

  uint public challengerStake;
  address public plcrVoting;
  uint public commitStageLength;
  uint public revealStageLength;
  uint public voteQuorum;
  uint public percentVoterReward;

  event PLCRVotingChallengeCreated(address challenge, address registry, address challenger);

  function initialize(
    uint _challengerStake,
    address _plcrVoting,
    uint _commitStageLength,
    uint _revealStageLength,
    uint _voteQuorum,
    uint _percentVoterReward
  )
    initializer
    public
  {
    challengerStake = _challengerStake;
    plcrVoting = _plcrVoting;
    commitStageLength = _commitStageLength;
    revealStageLength = _revealStageLength;
    voteQuorum = _voteQuorum;
    percentVoterReward = _percentVoterReward;
  }

  function createChallenge(address registry, address challenger, address itemOwner) public returns (address challenge) {
    challenge = new PLCRVotingChallenge(
      challenger,
      itemOwner,
      challengerStake,
      registry,
      plcrVoting,
      commitStageLength,
      revealStageLength,
      voteQuorum,
      percentVoterReward
    );

    emit PLCRVotingChallengeCreated(challenge, registry, challenger);
  }
}
