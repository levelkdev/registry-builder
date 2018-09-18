# Modular TCR Library

[Description]

### About

This library aims to be a readable and modular library for TCR's. Ideally developers can use these contracts to deploy their TCR or use these contracts as an extension onto their personalized TCR contract. However, if developers must make changes to these existing contracts to fit their needs, the hope is that these contracts are organized enough that you can alter them with ease. 

### Structure (a work in progress)

`Registry.sol`
```
contract Registry {
  mapping(bytes32 => bytes32) items;

  function add(bytes32 data) public returns (bytes32 id);
  function remove(bytes32 id) public;
  function get(bytes32 id) public constant returns (bytes32);
}
```

`StakedRegistry.sol`

Potentially looking into following EIP900 Staking Standard https://github.com/ethereum/EIPs/issues/900
```
contract StakedRegistry is Registry {
  mapping(bytes32 => ItemMetadata) itemsMetadata;

  struct ItemMetadata {
    address owner;
    uint stakedTokens;
  }
}
```

`TokenCuratedRegistry.sol`
```
TokenCuratedRegistry is StakedRegistry {
  mapping(bytes32 => ItemChallengeData) itemsChallengeData;
  
  struct ItemChallengeData {
    address challengeAddress;
    bool challengeResolved;
  }
  
  ChallengeFactory challengeFactory; // factory that creates a Challenge contract for challenged registry items
}
```
