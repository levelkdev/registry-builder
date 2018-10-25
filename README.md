# Modular TCR Library

#### *** DISCLAIMER: Current version contracts are not thoroughly tested or audited. Use at own risk ***

## About

This library aims to be a readable and modular library for registries and TCR's. Ideally developers can use these contracts to deploy their TCR or use these contracts as an extension onto their personalized registry contract.


## Setup
Install node modules:
```
$ npm install
```

Compile contracts:
```
$ npm run compile
```

Run tests:

```
$ npm run test
```


## Contract Structure

### Registry Interface

`IRegistry.sol `

```
interface IRegistry {
  function add(bytes32 data) public returns (bytes32 id);
  function remove(bytes32 id) public;
  function get(bytes32 id) public view returns (bytes32 item);
  function exists(bytes32 id) public view returns (bool itemExists);
}
```

### Challenge Interface
`IChallengeFactory.sol`

```
interface IChallengeFactory {
  function create(address registry, address challenger, address applicant) returns (address challenge);
}
```

`IChallenge.sol`

```
interface IChallenge {
  // returns the address of the challenger
  function challenger() view returns (address);

  // returns true if the challenge has ended
  function close() public;

  // returns whether challenge has been officially closed
  function isClosed() public view returns (bool);

  // returns true if the challenge has passed
  // reverts if challenge has not been closed
  function passed() public view returns (bool);

  // @notice returns the amount of tokens the challenge must
  // obtain to carry out functionality
  function fundsRequired() public view returns (uint);

  // @dev returns amount to be rewarded to challenge winner
  function winnerReward() public view returns (uint);
}
```

### Diagram
![Modular TCR](https://user-images.githubusercontent.com/5539720/45768348-a5134b00-bc0a-11e8-85f1-d41e9b476883.jpg)
