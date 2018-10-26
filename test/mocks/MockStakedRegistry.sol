pragma solidity ^0.4.24;

import '../../contracts/Registry/StakedRegistry.sol';

contract MockStakedRegistry is StakedRegistry {

  constructor(ERC20 _token, uint _minStake) public StakedRegistry(_token, _minStake) { }

  function setOwnerStake(bytes32 data, uint ownerStake) public {
    ownerStakes[data] = ownerStake;
  }

}
