pragma solidity ^0.4.24;

import "openzeppelin-zos/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-zos/contracts/math/SafeMath.sol";
import "plcr-revival/contracts/PLCRVoting.sol";
import "./IChallenge.sol";
import "../Registry/TokenCuratedRegistry.sol";

/**
 * @title PLCRVotingChallenge
 * @dev A challenge that uses Partial Lock Commit Reveal (PLCR) to allow token holders to cast
 * secret votes which are later revealed in order to reach a decision.
 */
contract PLCRVotingChallenge is IChallenge {
  using SafeMath for uint;

  // address of the challenger.
  address public challenger;

  // address of the item owner.
  address public itemOwner;

  // amount of tokens staked by the challenger.
  uint public challengerStake;

  // the registry contract that initiated the challenge.
  TokenCuratedRegistry public registry;

  // contract that will handle challenge voting.
  PLCRVoting public plcrVoting;

  // ID of the PLCRVoting poll.
  uint public pollId;

  // pool of tokens to be distributed to winning voters
  uint public voterRewardPool;

  // total amount of winning tokens that have been claimed by voters.
  uint public voterTokensClaimed;

  // total amount of token rewards that have been claimed by voters.
  uint public voterRewardsClaimed;

  // maps voter address to a bool indicating if the voter has claimed their reward.
  mapping(address => bool) public tokenClaims;   

  bool _isClosed;

  event ChallengeClosed();

  event RewardClaimed(uint reward, address voterAddress);

  /**
   * @dev Constructor for the new PLCRVotingChallenge contract.
   * @param _challenger The creator of the challenge.
   * @param _itemOwner The owner of the challenged item.
   * @param _challengerStake The amount of tokens staked by the challenger.
   * @param _registry The registry contract that initiated the challenge.
   * @param _plcrVoting The contract that will handle the PLCR voting poll.
   * @param commitStageLength The length of the period to commit new votes.
   * @param revealStageLength The length of the period to reveal votes.
   * @param voteQuorum The quorum needed for an outcome to win.
   * @param percentVoterReward The percent of stake that will be rewarded to voters (0 - 100).
   */
  constructor (
    address _challenger,
    address _itemOwner,
    uint _challengerStake,
    address _registry,
    address _plcrVoting,
    uint commitStageLength,
    uint revealStageLength,
    uint voteQuorum,
    uint percentVoterReward
  ) public {
    require(percentVoterReward <= 100);
    challenger = _challenger;
    itemOwner = _itemOwner;
    challengerStake = _challengerStake;
    registry = TokenCuratedRegistry(_registry);
    plcrVoting = PLCRVoting(_plcrVoting);
    pollId = plcrVoting.startPoll(voteQuorum, commitStageLength, revealStageLength);
    voterRewardPool = (percentVoterReward.mul(challengerStake)).div(100);
  }

  /**
   * @dev Closes the challenge, requires PLCR voting poll to have ended.
   */
  function close() public {
    require(plcrVoting.pollEnded(pollId) && !isClosed());
    _isClosed = true;

    emit ChallengeClosed();
  }

  /**
   * @dev Called by voters to claim rewards for winning votes.
   * @param _salt The salt of a voter's commit hash.
   */
  function claimVoterReward(uint _salt) public {
    require(isClosed());
    require(tokenClaims[msg.sender] == false); // Ensures the voter has not already claimed tokens

    uint voterTokens = plcrVoting.getNumPassingTokens(msg.sender, pollId);
    uint reward = voterReward(msg.sender, _salt);

    voterTokensClaimed = voterTokensClaimed.add(voterTokens);
    voterRewardsClaimed = voterRewardsClaimed.add(reward);

    // Ensures a voter cannot claim tokens again
    tokenClaims[msg.sender] = true;

    require(registry.token().transferFrom(registry, this, reward));
    require(registry.token().transfer(msg.sender, reward));

    RewardClaimed(reward, msg.sender);
  }

  /**
   * @return A uint amount of reward tokens to be allocted to the challenge winner.
   */
  function winnerReward() public view returns (uint) {
    require(isClosed());
    if (plcrVoting.getTotalNumberOfTokensForWinningOption(pollId) == 0) {
      return challengerStake.mul(2);
    } else {
      return (challengerStake.mul(2)).sub(voterRewardPool);
    }
  }

  /**
   * @dev Calculates a voter's token reward.
   * @param _voter The address of the voter whose reward balance is to be returned.
   * @param _salt The salt of the voter's commit hash.
   * @return The uint indicating the voter's reward.
   */
  function voterReward(address _voter, uint _salt) public view returns (uint) {
    uint voterTokens = plcrVoting.getNumPassingTokens(_voter, pollId);
    uint remainingVoterRewardPool = voterRewardPool.sub(voterRewardsClaimed);
    uint remainingTotalTokens = plcrVoting.getTotalNumberOfTokensForWinningOption(pollId).sub(voterTokensClaimed);
    return (voterTokens.mul(remainingVoterRewardPool)).div(remainingTotalTokens);
  }

  /**
   * @dev Checks if the challenge is closed.
   * @return A bool indicating whether the challenge is closed.
   */
  function isClosed() public view returns (bool) {
    return _isClosed;
  }

  /**
   * @dev Checks if the challenge has passed, reverts if the challenge has not been closed.
   * @return A bool indicating whether the challenge has passed.
   */
  function passed() public view returns (bool) {
      require(isClosed());

      // if voters do not vote in favor of item, challenge passes
      return !plcrVoting.isPassed(pollId);
  }

  /**
   * @return A uint amount of tokens the challenge needs to reward voters.
   */
  function fundsRequired() public view returns (uint) {
    return voterRewardPool;
  }

  /**
   * @return The address of the challenger.
   */
  function challenger() public view returns (address) {
    return challenger;
  }
}
