// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {TimeLockedSavings} from "../src/TimeLockedSavings.sol";

contract DeployTimeLockedSavings is Script {
    function run(address owner) public returns (TimeLockedSavings) {
        TimeLockedSavings timeLockedSavings;

        vm.startPrank(owner);
        timeLockedSavings = new TimeLockedSavings();
        vm.stopPrank();

        return timeLockedSavings;
    }
}
