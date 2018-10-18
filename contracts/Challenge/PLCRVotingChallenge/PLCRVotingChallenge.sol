pragma solidity ^0.4.24;

import "plcr-revival/contracts/PLCRVoting.sol";
import 'openzeppelin-zos/contracts/math/SafeMath.sol';
import '../IChallenge.sol';
import '../../Registry/TokenCuratedRegistry.sol';
import 'openzeppelin-zos/contracts/token/ERC20/ERC20.sol';

contract PLCRVotingChallenge is IChallenge {
  using SafeMath for uint;

  event ChallengeClosed();
  event RewardClaimed(uint reward, address voterAddress);

  address public challenger;     // address of the challenger
  address public listingOwner;   // address of the listingOwner
  uint public challengerStake;   // amount of tokens challenger staked in challenge
  TokenCuratedRegistry public registry;     // address of registry
  PLCRVoting public voting;      // address of PLCRVoting Contract
  uint public pollID;             // poll ID for PLCRVoting contract
  uint public rewardPool;        // pool of tokens to be distributed to winning voters
  bool public isClosed;          // signifies whether challenge has been closed
  uint public voterTokensClaimed;
  uint public voterRewardsClaimed;

  mapping(address => bool) public tokenClaims;   // Indicates whether a voter has claimed a reward yet

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
    rewardPool = (_percentVoterReward.mul(challengerStake)).div(100);
  }

  // ====================
  // CHALLENGE INTERFACE:
  // ====================

  // @notice Close challenge
  // @dev Closes challenge if PLCRVoting poll has ended and challenge
  //      is not yet closed
  function close() public {
    require(voting.pollEnded(pollID) && !isClosed);
    isClosed = true;

    require(registry.token().approve(registry, reward()));
    emit ChallengeClosed();
  }

  // @notice Determines if the challenge has passed
  // @dev Check if votesAgainst out of totalVotes exceeds votesQuorum (requires ended)
  function passed() public view returns (bool) {
      require(isClosed);

      // if votes do not vote in favor of listing, challenge passes
      return !voting.isPassed(pollID);
  }

  // =========================
  // WINNER REWARD INTERFACE:
  // =========================

  function reward() public view returns (uint rewardAmount) {
    require(isClosed);

    // Edge case, nobody voted, give all tokens to the challenger.
    if (voting.getTotalNumberOfTokensForWinningOption(pollID) == 0) {
      rewardAmount = challengerStake * 2;
    } else {
      rewardAmount = challengerStake * 2 - rewardPool;
    }
  }

  // =========================
  // VOTER REWARD INTERFACE:
  // =========================

  // @dev           Called by a voter to claim their reward for each completed vote
  // @param _salt   The salt of a voter's commit hash
  function claimVoterReward(uint _salt) public {
    require(isClosed);
    require(tokenClaims[msg.sender] == false); // Ensures the voter has not already claimed tokens

    uint voterTokens = voting.getNumPassingTokens(msg.sender, pollID);
    uint reward = voterReward(msg.sender, _salt);

    voterTokensClaimed += voterTokens;
    voterRewardsClaimed += reward;

    // Ensures a voter cannot claim tokens again
    tokenClaims[msg.sender] = true;
    require(registry.token().transfer(msg.sender, reward));

    RewardClaimed(reward, msg.sender);
  }

  // @dev            Calculates the provided voter's token reward.
  // @param _voter   The address of the voter whose reward balance is to be returned
  // @param _salt    The salt of the voter's commit hash in the given poll
  // @return         The uint indicating the voter's reward
  function voterReward(address _voter, uint _salt) public view returns (uint) {
      uint voterTokens = voting.getNumPassingTokens(_voter, pollID);
      uint remainingRewardPool = rewardPool - voterRewardsClaimed;
      uint remainingTotalTokens = voting.getTotalNumberOfTokensForWinningOption(pollID) - voterTokensClaimed;
      return (voterTokens * remainingRewardPool) / remainingTotalTokens;
  }

  function challenger() view returns (address) {
    return challenger;
  }
}
