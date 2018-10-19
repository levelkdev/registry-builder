pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract TestToken is  MintableToken {
  constructor (address[] _accounts, uint256 _amount)
    public
  {
    for (uint8 i = 0; i < _accounts.length; i++) {
      totalSupply_ = totalSupply_.add(_amount);
      balances[_accounts[i]] = balances[_accounts[i]].add(_amount);
    }
  }
}
