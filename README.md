# Raffle

A beginner-friendly Ethereum raffle smart contract built with Solidity and Foundry.

This project was built to practice Solidity fundamentals, ETH transfers, randomness concepts, events, custom errors, contract deployment, and Foundry testing.

> **Educational project:** The current winner-selection mechanism uses `block.timestamp` and `block.prevrandao` for learning purposes. This is not secure randomness for a production raffle. A production implementation should use a verifiable randomness solution such as Chainlink VRF.

## Features

- Enter the raffle by paying an exact entrance fee
- Track multiple players
- Pick a random winner
- Transfer the entire raffle balance to the winner
- Store the most recent winner
- Reset the player list after each round
- Allow the same player to participate in multiple rounds
- Emit entry and winner events
- Reject direct ETH transfers
- Handle failed ETH transfers
- Prevent picking a winner when there are no players
- Tested with Foundry
- Includes a Foundry deployment script

## Technologies

- Solidity `^0.8.30`
- Foundry
- Forge
- Ethereum Virtual Machine

## Contract Structure

```text
Raffle
│
├── enterRaffle()
│   └── Adds a player when the exact entrance fee is paid
│
├── pickWinner()
│   └── Selects a winner and transfers the raffle balance
│
├── getEntranceFee()
│   └── Returns the raffle entrance fee
│
├── getPlayer()
│   └── Returns a player at a given index
│
├── getLengthOfPlayers()
│   └── Returns the current number of players
│
├── getRecentWinner()
│   └── Returns the most recently selected winner
│
└── receive()
    └── Rejects direct ETH transfers
```

## Core Concepts Practiced

### Immutable Variables

The entrance fee is stored as an immutable variable:

```solidity
uint256 private immutable i_entranceFee;
```

It is assigned during deployment and cannot be changed afterward.

### Dynamic Arrays

Players are stored in a dynamic array:

```solidity
address payable[] private s_players;
```

Each player is added when they successfully enter the raffle.

### Custom Errors

Custom errors are used for failed conditions:

```solidity
error RaffleValueMustBeEqualToEntranceFee();
error RaffleNotEnoughPlayers();
error RaffleEthTransferFailed();
```

### Events

The contract emits events when players enter and when a winner is selected:

```solidity
event RaffleEntered(address indexed _player);
event WinnerPicked(address indexed _winner);
```

The indexed player and winner addresses can be used by external applications and blockchain explorers to filter raffle activity.

### ETH Transfer

The winner receives the entire contract balance using a low-level `call`:

```solidity
(bool success,) = winner.call{value: address(this).balance}("");
```

The transaction reverts if the transfer fails.

### Winner Selection

The current educational implementation derives a pseudo-random value from:

```solidity
keccak256(
    abi.encodePacked(
        block.timestamp,
        block.prevrandao
    )
);
```

The result is used to select a player index.

This approach is useful for understanding the mechanics of randomness and array indexing, but it should **not** be used for a production raffle because block-derived values can be influenced or predicted to some degree.

## Testing

The test suite covers normal behavior, edge cases, events, ETH transfers, failed transfers, and multiple raffle rounds.

### Entrance Tests

- Raffle starts with a zero balance
- Constructor stores the correct entrance fee
- Incorrect entrance fees are rejected
- Zero-value entries are rejected
- Payments greater than the entrance fee are rejected
- Players can enter successfully
- Multiple players can enter
- Entry events contain the correct player
- Direct ETH transfers are rejected

### Winner Tests

- Picking a winner with no players reverts
- A winner is selected after players enter
- The recent winner is updated
- The winner event contains the expected winner
- The winner receives the entire raffle balance
- The raffle balance becomes zero after payout
- The player list is reset after a winner is picked
- The raffle can run multiple rounds
- The same player can enter multiple rounds

### Failure Tests

A `RejectingReceiver` helper contract is used to simulate a failed ETH transfer.

```text
RejectingReceiver
       ↓
enter raffle
       ↓
Raffle::enterRaffle()
       ↓
pickWinner()
       ↓
ETH sent to RejectingReceiver
       ↓
receive() reverts
       ↓
RaffleEthTransferFailed
```

## Project Structure

```text
Raffle/
│
├── src/
│   └── Raffle.sol
│
├── script/
│   └── DeployRaffle.s.sol
│
├── test/
│   └── RaffleTest.t.sol
│
├── foundry.toml
├── README.md
└── lib/
```

## Running the Tests

Clone the repository and navigate into the project:

```bash
cd Raffle
```

Build the project:

```bash
forge build
```

Run all tests:

```bash
forge test
```

Run tests with increased verbosity:

```bash
forge test -vv
```

For detailed execution traces:

```bash
forge test -vvvv
```

Run a specific test:

```bash
forge test --match-test testName -vv
```

## Deployment

The project includes a Foundry deployment script:

```text
script/
└── DeployRaffle.s.sol
```

The script deploys a new `Raffle` contract with an entrance fee of `0.01 ether`.

Run the deployment script locally:

```bash
forge script script/DeployRaffle.s.sol:DeployRaffle
```

For network deployment, configure the appropriate RPC URL and private key through environment variables and use Foundry's broadcast options.


## What I Learned

Through this project, I practiced:

- Solidity immutable variables
- Dynamic arrays
- Custom errors
- Events and indexed parameters
- `msg.sender`
- `msg.value`
- ETH transfers
- Low-level `call`
- `address(this).balance`
- `receive()`
- `block.timestamp`
- `block.prevrandao`
- `keccak256`
- `abi.encodePacked`
- Array indexing
- Foundry unit testing
- `vm.prank()`
- `vm.hoax()`
- `vm.deal()`
- `vm.expectRevert()`
- `vm.expectEmit()`
- `vm.warp()`
- `vm.prevrandao()`
- Deployment scripts

## Future Improvements

Possible improvements for future versions include:

- Replace pseudo-randomness with Chainlink VRF
- Add raffle states
- Add Chainlink Automation
- Add a configurable entrance fee
- Add a minimum number of players
- Add fuzz testing
- Add invariant testing
- Add a frontend
- Deploy to a testnet
- Add automated CI testing with GitHub Actions

## License

This project is licensed under the MIT License.
