pragma solidity ^0.4.24;

import 'openzeppelin-eth/contracts/token/ERC20/ERC20.sol';

contract TestToken is ERC20 {
  constructor (address[] _accounts, uint256 _amount)
    public
  {
    for (uint8 i = 0; i < _accounts.length; i++) {
      mint(_accounts[i], _amount);
    }
  }

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }
}
