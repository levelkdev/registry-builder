# registry-builder

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

## Using from ZeppelinOS

You can create a TCR instance using [ZeppelinOS](http://zeppelinos.org/) by linking to this [EVM package](https://docs.zeppelinos.org/docs/linking.html). This will use the logic contracts already deployed to mainnet, kovan, ropsten, or rinkeby, reducing your gas deployment costs. 

As an example, to create an instance of a registry using ZeppelinOS, run the following commands:
 ```bash
$ npm install -g zos
$ zos init YourProject
$ zos link registry-builder
$ zos push --network rinkeby
> Connecting to dependency registry-builder 0.1.0
$ zos create registry-builder/OwnedItemRegistry --network rinkeby --from $SENDER
> Instance created at ADDRESS
```

It is strongly suggested to [use a non-default address](https://docs.zeppelinos.org/docs/pattern.html#transparent-proxies-and-function-clashes) (this is, not the first address in your node) as `$SENDER`.

Check out this [**example project**](https://github.com/levelkdev/registry-builder-example) for creating a [more interesting full TCR](https://github.com/levelkdev/registry-builder-example/blob/master/deploy/deploy.js) instead of a basic owned item registry.

## Contract Structure

### Registry Interface

`IRegistry.sol `

```
interface IRegistry {
  function add(bytes32 data) public;
  function remove(bytes32 data) public;
  function exists(bytes32 data) public view returns (bool item);
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


## Code Review
* Notes on current state of this repository: https://docs.google.com/document/d/1vjaWW7izisc2QNlZEpti4BPh8yJTOGo3Wu9GNgaRI1A/
* Feel free to create an Issue with review, questions, or concerns.
