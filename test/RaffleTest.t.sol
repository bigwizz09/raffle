// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    RejectingReceiver public receiver;

    uint256 raffleEntranceFee = 0.01 ether;

    address Bob = makeAddr("bob");
    address Alice = makeAddr("Alice");

    uint256 startingBalance = 1 ether;

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle) = deployer.run();
        receiver = new RejectingReceiver(raffle);
        vm.deal(Bob, startingBalance);
        vm.deal(Alice, startingBalance);
    }

    function testRaffleBalanceStartAtZero() public {
        assertEq(address(raffle).balance, 0);
    }

    function testConstructorPassedInCorrectEntranceFee() public view {
        assertEq(raffle.getEntranceFee(), raffleEntranceFee);
    }

    function testEntryFeeValidation() public {
        vm.prank(Bob);
        vm.expectRevert(Raffle.RaffleValueMustBeEqualToEntranceFee.selector);
        raffle.enterRaffle{value: 0.001 ether}();
    }

    function testPlayerCanEnterRaffle() public {
        vm.prank(Bob);
        raffle.enterRaffle{value: raffleEntranceFee}();
        assertEq(raffle.getPlayer(0), Bob);
    }

    function testMultiplePlayers() public {
        // Arrange
        vm.prank(Bob);
        raffle.enterRaffle{value: raffleEntranceFee}();

        vm.prank(Alice);
        raffle.enterRaffle{value: raffleEntranceFee}();

        assertEq(raffle.getPlayer(0), Bob);
        assertEq(raffle.getPlayer(1), Alice);
        assertEq(raffle.getLengthOfPlayers(), 2);
    }

    function testEventEmitsOnEntrance() public {
        // Arrange
        vm.prank(Bob);

        // Act /Assert
        vm.expectEmit(true, false, false, false);
        emit Raffle.RaffleEntered(Bob);
        raffle.enterRaffle{value: raffleEntranceFee}();
    }

    function testWinnerPicked() public {
        address player0 = address(0);
        address player1 = address(1);
        address player2 = address(2);

        address expectedWinner;
        // Arrange
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 0; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether); // deal 1 eth to the player
            raffle.enterRaffle{value: raffleEntranceFee}();
        }
        uint256 player0StartBalance = player0.balance;
        uint256 player1StartBalance = player1.balance;

        raffle.pickWinner();
        uint256 prize = raffleEntranceFee * additionalEntrances;

        if (player0.balance - player0StartBalance == prize) {
            expectedWinner = player0;
        } else if (player1.balance - player1StartBalance == prize) {
            expectedWinner = player1;
        } else {
            expectedWinner = player2;
        }

        assertEq(raffle.getRecentWinner(), expectedWinner);
        assertEq(raffle.getLengthOfPlayers(), 0);
    }

    function testCannotPickWinnerIfNoPlayers() public {
        vm.expectRevert(Raffle.RaffleNotEnoughPlayers.selector);
        raffle.pickWinner();
    }

    function testEventEmitsOnWinnerPicked() public {
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 0;

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether);
            raffle.enterRaffle{value: raffleEntranceFee}();
        }

        vm.warp(100);
        vm.prevrandao(200);

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao)));
        uint256 expectedWinnerIndex = randomNumber % raffle.getLengthOfPlayers();
        address expectedWinner = raffle.getPlayer(expectedWinnerIndex);
        vm.expectEmit(true, false, false, false);
        emit Raffle.WinnerPicked(expectedWinner);
        raffle.pickWinner();
    }

    function testTransferFailCase() public {
        receiver.enter{value: raffleEntranceFee}();
        vm.expectRevert(Raffle.RaffleEthTransferFailed.selector);
        raffle.pickWinner();
    }

    function testPickWinnerRevertsWhenThereIsNoPlayer() public {
        vm.expectRevert(Raffle.RaffleNotEnoughPlayers.selector);
        raffle.pickWinner();
    }

    function testRaffleTransfersEntireBalanceToWinner() public {
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 0;

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether);
            raffle.enterRaffle{value: raffleEntranceFee}();
        }

        vm.warp(100);
        vm.prevrandao(200);

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao)));
        uint256 expectedWinnerIndex = randomNumber % raffle.getLengthOfPlayers();
        address expectedWinner = raffle.getPlayer(expectedWinnerIndex);
        uint256 totalBalance = raffleEntranceFee * additionalEntrances;
        uint256 expectedWinnerStartingBalance = expectedWinner.balance;

        raffle.pickWinner();
        assertEq(expectedWinner.balance, expectedWinnerStartingBalance + totalBalance);
        assertEq(address(raffle).balance, 0);
    }

    function testRaffleCanRunMultipleRounds() public {
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 0;

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether);
            raffle.enterRaffle{value: raffleEntranceFee}();
        }

        assertEq(raffle.getLengthOfPlayers(), 3);

        raffle.pickWinner();
        assertEq(raffle.getLengthOfPlayers(), 0);

        vm.prank(Bob);
        raffle.enterRaffle{value: raffleEntranceFee}();

        assertEq(raffle.getLengthOfPlayers(), 1);

        raffle.pickWinner();
        assertEq(raffle.getLengthOfPlayers(), 0);
    }

    function testRaffleEnteredEventsContainsCorrectPlayerAddress() public {
        vm.prank(Bob);
        vm.expectEmit(true, false, false, false);
        emit Raffle.RaffleEntered(Bob);
        raffle.enterRaffle{value: raffleEntranceFee}();
    }

    function testRaffleRevertsWhenEntranceFeeIsZero() public {
        vm.prank(Bob);
        vm.expectRevert(Raffle.RaffleValueMustBeEqualToEntranceFee.selector);
        raffle.enterRaffle{value: 0}();
    }

    function testRaffleRevertsWhenPlayerSendMoreEthThanEntranceFee() public {
        vm.prank(Bob);
        vm.expectRevert(Raffle.RaffleValueMustBeEqualToEntranceFee.selector);
        raffle.enterRaffle{value: 0.5 ether}();
    }

    function testDirectEthTransferReverts() public {
        vm.prank(Bob);
        vm.expectRevert();

        payable(address(raffle)).transfer(raffleEntranceFee);
    }

    function testRecentWinnerIsUpdated() public {
        vm.prank(Bob);
        raffle.enterRaffle{value: raffleEntranceFee}();

        raffle.pickWinner();
        assertEq(raffle.getRecentWinner(), Bob);
    }

    function testSamePlayerCanEnterMultipleRounds() public {
        vm.prank(Bob);
        raffle.enterRaffle{value: raffleEntranceFee}();
        assertEq(raffle.getLengthOfPlayers(), 1);

        raffle.pickWinner();
        assertEq(raffle.getLengthOfPlayers(), 0);

        vm.prank(Bob);
        raffle.enterRaffle{value: raffleEntranceFee}();
        assertEq(raffle.getLengthOfPlayers(), 1);

        raffle.pickWinner();
        assertEq(raffle.getLengthOfPlayers(), 0);
    }
}

contract RejectingReceiver {
    Raffle public raffle;

    constructor(Raffle _raffle) {
        raffle = _raffle;
    }

    function enter() external payable {
        raffle.enterRaffle{value: msg.value}();
    }

    receive() external payable {
        revert();
    }
}
