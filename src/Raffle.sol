// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Raffle {
    error RaffleValueMustBeEqualToEntranceFee();
    error RaffleNotEnoughPlayers();
    error RaffleEthTransferFailed();

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    address private s_recentWinner;

    event RaffleEntered(address indexed _player);
    event WinnerPicked(address indexed _winner);

    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
    }

    function enterRaffle() public payable {
        require(msg.value == i_entranceFee, RaffleValueMustBeEqualToEntranceFee());
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function pickWinner() public {
        require(s_players.length >= 1, RaffleNotEnoughPlayers());
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao)));

        uint256 winnerIndex = randomNumber % s_players.length;
        address payable winner = s_players[winnerIndex];

        (bool success,) = winner.call{value: address(this).balance}("");
        require(success, RaffleEthTransferFailed());
        s_players = new address payable[](0);
        s_recentWinner = winner;

        emit WinnerPicked(winner);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 _index) public view returns (address) {
        return s_players[_index];
    }

    function getLengthOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    receive() external payable{
        revert();
    }
}
