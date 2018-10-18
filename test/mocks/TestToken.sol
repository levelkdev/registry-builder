pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract TestToken is DetailedERC20, MintableToken {
  constructor (string _name, string _symbol, uint8 _decimals, address[] _accounts, uint256 _amount)
    public
    DetailedERC20(_name, _symbol, _decimals)
  {
    for (uint8 i = 0; i < _accounts.length; i++) {
      totalSupply_ = totalSupply_.add(_amount);
      balances[_accounts[i]] = balances[_accounts[i]].add(_amount);
    }
  }
}
