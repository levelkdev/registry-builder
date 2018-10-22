pragma solidity ^0.4.24;

import 'openzeppelin-zos/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-zos/contracts/math/SafeMath.sol';
import "plcr-revival/contracts/PLCRVoting.sol";
import '../IChallenge.sol';
import '../../Registry/TokenCuratedRegistry.sol';

/**
 * PLCRVotingChallenge is a registry challenge that creates a poll on a
 * PLCRVoting Contract where voters decide whether to keep or accept an
 * item onto the registry
 *
 * This Challenge contract interfaces with PLCRVoting, communicates results to the
 * registry, and distributes voter rewards
**/
contract PLCRVotingChallenge is IChallenge {
  using SafeMath for uint;

  event ChallengeClosed();
  event RewardClaimed(uint reward, address voterAddress);

  address public challenger;             // address of the challenger
  address public listingOwner;           // address of the listingOwner
  uint public challengerStake;           // amount of tokens challenger staked in challenge
  TokenCuratedRegistry public registry;  // address of registry
  PLCRVoting public voting;              // address of PLCRVoting Contract
  uint public pollID;                    // poll ID for PLCRVoting contract
  uint public voterRewardPool;           // pool of tokens to be distributed to winning voters
  bool public isClosed;                  // signifies whether challenge has been closed
  uint public voterTokensClaimed;        // total amount of winning tokens voters have received rewards for thus far
  uint public voterRewardsClaimed;       // total amount of rewards distributed to voters thus far

  mapping(address => bool) public tokenClaims;   // Indicates whether a voter has claimed their reward yet

  // @dev create new challenge
  // @param _challenger           account that challenged registry item
  // @param _listingOwner         account of listingOwner
  // @param _challengerStake      amount challenger staked for challenge
  // @param _registry             registry contract
  // @param _plcrVoting           PLCRVoting contract with voting poll
  // @param _commitStageLength    commitStageLength for PLCRVoting poll
  // @param _revealStageLength    revealStageLength for PLCRVoting poll
  // @param _voteQuorum           voteQuorum needed for winning outcome
  // @param _percentVoterReward   percent of challengerStake rewarded to voters
  constructor (
    address _challenger,
    address _listingOwner,
    uint _challengerStake,
    address _registry,
    address _plcrVoting,
    uint commitStageLength,
    uint revealStageLength,
    uint voteQuorum,
    uint _percentVoterReward
  ) public {
    require(_percentVoterReward <= 100);
    challenger = _challenger;
    listingOwner = _listingOwner;
    challengerStake = _challengerStake;
    registry = TokenCuratedRegistry(_registry);
    voting = PLCRVoting(_plcrVoting);
    pollID = voting.startPoll(voteQuorum, commitStageLength, revealStageLength);
    voterRewardPool = (_percentVoterReward.mul(challengerStake)).div(100);
  }

  // @notice Close challenge
  // @dev Closes challenge if PLCRVoting poll has ended and challenge
  //      is not yet closed
  function close() public {
    require(voting.pollEnded(pollID) && !isClosed);
    isClosed = true;

    emit ChallengeClosed();
  }

  // @notice Determines if the challenge has passed
  // @dev Check if votesAgainst out of totalVotes exceeds votesQuorum
  //      returns true if PLCR voting has passed
  //      returns false if PLCR voting has not passed
  //      reverts if challenge has not been closed.
  function passed() public view returns (bool) {
      require(isClosed);

      // if voters do not vote in favor of item, challenge passes
      return !voting.isPassed(pollID);
  }

  // @notice Returns the amount of tokens the challenge needs to
  //         carry out functionality
  // @dev    returns voterRewardPool so the challenge can disburse
  //         voter rewards
  function requiredFundsAmount() public view returns (uint) {
    return voterRewardPool;
  }

  // @dev   returns the total reward amount to be distributed to challenge winner
  function winnerReward() public view returns (uint) {
    require(isClosed);
    if (voting.getTotalNumberOfTokensForWinningOption(pollID) == 0) {
      return challengerStake.mul(2);
    } else {
      return (challengerStake.mul(2)).sub(voterRewardPool);
    }
  }

  // @dev           Called by a voter to claim their reward for each completed vote
  // @param _salt   The salt of a voter's commit hash
  function claimVoterReward(uint _salt) public {
    require(isClosed);
    require(tokenClaims[msg.sender] == false); // Ensures the voter has not already claimed tokens

    uint voterTokens = voting.getNumPassingTokens(msg.sender, pollID);
    uint reward = voterReward(msg.sender, _salt);

    voterTokensClaimed = voterTokensClaimed.add(voterTokens);
    voterRewardsClaimed = voterRewardsClaimed.add(reward);

    // Ensures a voter cannot claim tokens again
    tokenClaims[msg.sender] = true;

    require(registry.token().transferFrom(registry, this, reward));
    require(registry.token().transfer(msg.sender, reward));

    RewardClaimed(reward, msg.sender);
  }

  // @dev            Calculates the provided voter's token reward.
  // @param _voter   The address of the voter whose reward balance is to be returned
  // @param _salt    The salt of the voter's commit hash in the given poll
  // @return         The uint indicating the voter's reward
  function voterReward(address _voter, uint _salt) public view returns (uint) {
      uint voterTokens = voting.getNumPassingTokens(_voter, pollID);
      uint remainingvoterRewardPool = voterRewardPool.sub(voterRewardsClaimed);
      uint remainingTotalTokens = voting.getTotalNumberOfTokensForWinningOption(pollID).sub(voterTokensClaimed);
      return (voterTokens.mul(remainingvoterRewardPool)).div(remainingTotalTokens);
  }

  // @dev returns challenger address
  function challenger() view returns (address) {
    return challenger;
  }
}
