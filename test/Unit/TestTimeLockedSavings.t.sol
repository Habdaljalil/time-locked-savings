// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployTimeLockedSavings} from "../../script/DeployTimeLockedSavings.s.sol";
import {TimeLockedSavings} from "../../src/TimeLockedSavings.sol";

contract TestTimeLockedSavings is Test {
    TimeLockedSavings timeLockedSavings;
    address internal owner = makeAddr("Hassan");

    function setUp() public {
        DeployTimeLockedSavings deployTimeLockedSavings = new DeployTimeLockedSavings();
        timeLockedSavings = deployTimeLockedSavings.run(owner);
    }

    function testOwner() public view {
        assertEq(timeLockedSavings.getOwner(), owner);
    }
}