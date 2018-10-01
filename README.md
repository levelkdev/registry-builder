# Modular TCR Library

## About

This library aims to be a readable and modular library for TCR's. Ideally developers can use these contracts to deploy their TCR or use these contracts as an extension onto their personalized TCR contract. However, if developers must make changes to these existing contracts to fit their needs, the hope is that these contracts are organized enough that you can alter them with ease.

## Structure (a work in progress)
** Plan to eventually incorporate a `Parameterizer.sol` for certain vars

### Registry

`BasicRegistry.sol`

```
contract BasicRegistry {
  mapping(bytes32 => bytes32) items;

  function add(bytes32 data) public returns (bytes32 id);
  function remove(bytes32 id) public;
  function get(bytes32 id) public constant returns (bytes32);
  function exists(bytes32 id) public view returns (bool);
}
```

`OwnedItemRegistry.sol`

Sets the msg.sender of the `add` transaction as the owner of the added item. Only allows the owner of the item to remove it.

```
contract OwnedItemRegistry is BasicRegistry {
  modifier onlyItemOwner(bytes32 id);

  mapping(bytes32 => address) public owners;

  function add(bytes32 data) public returns (bytes32 id);
  function remove(bytes32 id) public onlyItemOwner(id);
}
```

`StakedRegistry.sol`

Handles token stake for owned items. Requires a minimum stake. Allows the owner to increase or decrease stake, as long as it remains above the minimum stake.

```
contract StakedRegistry is OwnedItemRegistry {
  ERC20 token;
  uint minStake;      // minimum required amount of tokens to add an item

  mapping(bytes32 => uint) public ownerStakes;

  function add(bytes32 data) public returns (bytes32 id);
  function remove(bytes32 id) public onlyItemOwner(id);
  function increaseStake(bytes32 id, uint stakeAmount) public onlyItemOwner(id);
  function decreaseStake(bytes32 id, uint stakeAmount) public onlyItemOwner(id);
}
```

`LockableItemRegistry.sol`

Provides a mapping of unlock times for items. Only allows item removal when the unlock time has been exceeded.

```
contract LockableItemRegistry is OwnedItemRegistry {
  mapping(bytes32 => uint) public unlockTimes;

  function remove(bytes32 id) public;
  function isLocked(bytes32 id) public view returns (bool);
}
```


`TokenCuratedRegistry.sol`

```
TokenCuratedRegistry is StakedRegistry {
  uint applicationPeriod;
  IChallengeFactory public challengeFactory;
  mapping(bytes32 => IChallenge) public challenges;

  // Adds an item to the `items` mapping, transfers token stake from msg.sender, and locks
  // the item from removal until now + applicationPeriod.
  function add(bytes32 data) public returns (bytes32 id);

  // Removes an item from the `items` mapping, and deletes challenge state. Requires that
  // there is not an active or passed challenge for this item. OwnedItemRegistry.remove
  // requires that this is called by the item owner. LockableItemRegistry.remove requires
  // that the item is not locked.
  function remove(bytes32 id) public;

  // Creates a new challenge for an item.
  // Requires that the item exists, and that there is no existing challenge for the item.
  // Requires msg.sender (the challenger) to match the owner's stake by transferring to
  // this contract. The challenger's and owner's stake is transferred to the newly created
  // challenge contract.
  function challenge(bytes32 id) public;

  // Handles transfer of reward after a challenge has ended. Requires that there
  // is an ended challenge for the item.
  function resolveChallenge(bytes32 id) public;

  // Returns true if the item exists and is not locked. We know that locked items are in
  // the application phase, because the unlock time is set to now + applicationPeriod when
  // items are added. Also, unlock time is set to 0 if an item is challenged and the
  // challenge fails.
  function inApplicationPhase(bytes32 id) public view returns (bool);
}
```

### Challenge
`IChallengeFactory.sol`

```
interface IChallengeFactory {
  function create(address registry, address challenger, address applicant) returns (address challenge);
}
```

`IChallenge.sol`

```
interface IChallenge {
  // returns true if the challenge has ended
  function ended() view returns(bool);

  // returns true if the challenge has passed
  function passed() view returns (bool);

  // returns the amount of tokens to transfer back to the registry contract
  // after the challenge has eneded, to be distributed as a reward for applicant/challenger
  function reward() view returns (uint);

  // returns the address of the challenger
  function challenger() view returns (address);
}
```

### Diagram
![Modular TCR](https://user-images.githubusercontent.com/5539720/45768348-a5134b00-bc0a-11e8-85f1-d41e9b476883.jpg)
