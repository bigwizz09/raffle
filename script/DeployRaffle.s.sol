// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    uint256 entranceFee = 0.01 ether;

    function run() public returns (Raffle) {
        vm.startBroadcast();
        Raffle raffle = new Raffle(entranceFee);
        vm.stopBroadcast();

        return raffle;
    }
}
