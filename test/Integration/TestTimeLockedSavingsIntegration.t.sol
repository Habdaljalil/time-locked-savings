// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployTimeLockedSavings} from "../../script/DeployTimeLockedSavings.s.sol";
import {TimeLockedSavings} from "../../src/TimeLockedSavings.sol";
import {TimeLockedSavingsLibrary} from "../../src/TimeLockedSavingsLibrary.sol";
import {BadReceiver} from "../Mocks/BadReceiver.sol";
import {TestTimeLockedSavings} from "../Unit/TestTimeLockedSavings.t.sol";
import {console} from "forge-std/console.sol";

contract TestTimeLockedSavingsIntegration is TestTimeLockedSavings {


    modifier safeAddresses(address user) {
        vm.assume(user.code.length == 0);
        vm.assume(user != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        vm.assume(user != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.assume(user != address(0));
        vm.assume(uint160(user) > 20); // no precompiles
        vm.assume(user != address(timeLockedSavings)); // THIS FIXES IT
        vm.assume(user != address(this)); // test contract
        _;
    }


    function testDepositIntegration(address user, uint256 depositAmount, uint256 duration) public safeAddresses(user) {
        vm.assume(depositAmount > 0);
        vm.assume(duration > 0);
        vm.deal(user, depositAmount);
        vm.startPrank(user);
        vm.expectEmit(true, true, true, false);
        emit TimeLockedSavingsLibrary.Deposited(user, block.timestamp, depositAmount);
        timeLockedSavings.deposit{value: depositAmount}(duration);
        vm.stopPrank();

        TimeLockedSavingsLibrary.Deposit memory userDeposit = timeLockedSavings.getUserToDeposits(user)[0];

        assertEq(userDeposit.amount, depositAmount);
        assertEq(userDeposit.unlockTime, duration);
        assertEq(userDeposit.withdrawn, false);
    }

    function testWithdrawIntegration(address user, uint256 depositAmount, uint256 duration) public safeAddresses(user) {
        vm.assume(depositAmount > 0);
        vm.assume(duration > 0);
        vm.assume(duration < 2 ** 256 - 1);

        vm.deal(user, depositAmount);
        console.log(payable(user).balance);
        vm.startPrank(user);

        timeLockedSavings.deposit{value: depositAmount}(duration);
        vm.stopPrank();

        console.log(block.timestamp);

        skip(duration); // when timestamp = 1 and duration = max of uint256 --> overflow error;

        console.log(payable(user).balance);
        console.log(block.timestamp, duration);

        vm.expectEmit(true, true, true, false);
        emit TimeLockedSavingsLibrary.Withdraw(user, block.timestamp, depositAmount);
        console.log(timeLockedSavings.getUserToDeposits(user)[0].amount); // Everything works
        console.log(timeLockedSavings.getUserToDeposits(user)[0].unlockTime); // except the withdraw function in the TimeLockedSavings.sol for some reason
        vm.startPrank(user);
        //console.log(timeLockedSavings.getUserToDeposits(user).length); // The user has a deposit with money at index 0
        timeLockedSavings.withdraw(0); // Why? --> the main issue is in TimeLockedSavings
        vm.stopPrank();

        assertEq(payable(user).balance, depositAmount);
    }
}
