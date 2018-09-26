# Modular TCR Library

## About

This library aims to be a readable and modular library for TCR's. Ideally developers can use these contracts to deploy their TCR or use these contracts as an extension onto their personalized TCR contract. However, if developers must make changes to these existing contracts to fit their needs, the hope is that these contracts are organized enough that you can alter them with ease.

## Structure (a work in progress)

### Registry

`BasicRegistry.sol`

```
contract BasicRegistry {
  mapping(bytes32 => bytes32) items;

  function add(bytes32 data) public returns (bytes32 id);
  function remove(bytes32 id) public;
  function get(bytes32 id) public constant returns (bytes32);
}
```

`OwnedRegistry.sol`

```
contract OwnedRegistry is BasicRegistry {
   modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
   address owner;
   
   function add(bytes32 data) public onlyOwner returns (bytes32 id);
   function remove(bytes32 id) public onlyOwner;
}
```

`StakedRegistry.sol`

```
contract StakedRegistry is BasicRegistry {
  mapping(bytes32 => ItemMetadata) itemsMetadata;

  struct ItemMetadata {
    address owner;
    uint stakedTokens;
  }
  
  ERC20 token;
  uint minStake; // the minimum required amount of tokens staked
}
```

`TokenCuratedRegistry.sol`

```
TokenCuratedRegistry is StakedRegistry {
  mapping(bytes32 => ItemCurationData) itemsCurationData;

  struct ItemCurationData {
    uint applicationExpiry;
    bool whitelisted;
    address challengeAddress;
    bool challengeResolved;
  }

  ChallengeFactory challengeFactory; // factory that creates a Challenge contract for each newly challenged registry item
  uint applicationPeriod;
  
  function challenge(bytes32 id) external returns (address challenge);
  functionm updateStatus(bytes32 id) external;
}
```

### Challenge
`ChallengeFactory.sol`

```
interface ChallengeFactory {
  function createChallenge(address registry, address challenger, address itemOwner) returns (address challenge);
}

```

`Challenge.sol`

```
interface Challenge {
  function ended() public view returns (bool);

  function passed() public view returns (bool);

  // amount of tokens the Challenge will need to carry out operation
  function requiredTokenAmount() public view returns (uint256);

  // amount of tokens the Challenge will return to registry after conclusion (ie: winner reward)
  function returnTokenAmount() public view returns (uint256);
}
```
### Diagram
![Modular TCR](https://user-images.githubusercontent.com/5539720/45768348-a5134b00-bc0a-11e8-85f1-d41e9b476883.jpg)
