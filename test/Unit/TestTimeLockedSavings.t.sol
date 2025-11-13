// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployTimeLockedSavings} from "../../script/DeployTimeLockedSavings.s.sol";
import {TimeLockedSavings} from "../../src/TimeLockedSavings.sol";
import {TimeLockedSavingsLibrary} from "../../src/TimeLockedSavingsLibrary.sol";
import {BadReceiver} from "../Mocks/BadReceiver.sol";

contract TestTimeLockedSavings is Test {
    TimeLockedSavings timeLockedSavings;
    address internal owner = makeAddr("Hassan");
    address internal user1 = makeAddr("User 1");
    address internal badReceiver = address(new BadReceiver());
    uint256 constant DEPOSIT_AMOUNT = 5 ether;
    uint256 constant DURATION = 1 minutes;

    function setUp() public {
        DeployTimeLockedSavings deployTimeLockedSavings = new DeployTimeLockedSavings();
        timeLockedSavings = deployTimeLockedSavings.run(owner);
    }

    modifier userDepositedSuccessfully(address user) {
        vm.deal(user, DEPOSIT_AMOUNT);
        vm.startPrank(user);
        timeLockedSavings.deposit{value: DEPOSIT_AMOUNT}(DURATION);
        vm.stopPrank();
        _;
    }

    function testOwner() public view {
        assertEq(timeLockedSavings.getOwner(), owner);
    }

    function testDeposit() public {
        vm.deal(user1, DEPOSIT_AMOUNT);

        vm.expectEmit(true, true, true, false);
        emit TimeLockedSavingsLibrary.Deposited(user1, block.timestamp, DEPOSIT_AMOUNT);

        vm.startPrank(user1);
        timeLockedSavings.deposit{value: DEPOSIT_AMOUNT}(DURATION);
        vm.stopPrank();

        TimeLockedSavingsLibrary.Deposit memory userDeposit = timeLockedSavings.getUserToDeposits(user1)[0];

        assertEq(userDeposit.amount, DEPOSIT_AMOUNT);
        assertEq(userDeposit.unlockTime, DURATION);
        assertEq(userDeposit.withdrawn, false);
    }

    function testDepositNoFunds() public {
        vm.expectRevert(abi.encodeWithSelector(TimeLockedSavingsLibrary.NOT__ENOUGH__FUNDS.selector, 0));
        vm.startPrank(user1);
        timeLockedSavings.deposit{value: 0}(DURATION);
        vm.stopPrank();
    }

    function testDepositNoDuration() public {
        vm.deal(user1, DEPOSIT_AMOUNT);
        vm.expectRevert(abi.encodeWithSelector(TimeLockedSavingsLibrary.NOT__ENOUGH__TIME.selector, 0));
        vm.startPrank(user1);
        timeLockedSavings.deposit{value: DEPOSIT_AMOUNT}(0);
        vm.stopPrank();
    }

    function testWithdraw() public userDepositedSuccessfully(user1) {
        skip(DURATION);
        vm.expectEmit(true, true, true, false);
        emit TimeLockedSavingsLibrary.Withdraw(user1, vm.getBlockTimestamp(), DEPOSIT_AMOUNT);
        vm.startPrank(user1);
        timeLockedSavings.withdraw(0);
        vm.stopPrank();
    }

    function testWithdrawNonExistant() public userDepositedSuccessfully(user1) {
        skip(DURATION);
        vm.expectRevert(abi.encodeWithSelector(TimeLockedSavingsLibrary.DEPOSIT__DOES__NOT__EXIST.selector, 1));
        vm.startPrank(user1);
        timeLockedSavings.withdraw(1);
        vm.stopPrank();
    }

    function testWithdrawNoDeposits() public {
        skip(DURATION);
        vm.expectRevert(TimeLockedSavingsLibrary.NO__DEPOSITS.selector);
        vm.startPrank(user1);
        timeLockedSavings.withdraw(0);
        vm.stopPrank();
    }

    function testWithdrawTooEarly() public userDepositedSuccessfully(user1) {
        vm.expectRevert(abi.encodeWithSelector(TimeLockedSavingsLibrary.WITHDRAW__TOO__EARLY.selector, block.timestamp));
        vm.startPrank(user1);
        timeLockedSavings.withdraw(0);
        vm.stopPrank();
    }

    function testWithdrawBadReceiver() public userDepositedSuccessfully(user1) {
        vm.deal(badReceiver, DEPOSIT_AMOUNT);
        vm.startPrank(badReceiver);
        timeLockedSavings.deposit{value: DEPOSIT_AMOUNT}(DURATION);
        vm.stopPrank();

        skip(DURATION);

        vm.expectRevert();
        vm.startPrank(badReceiver);
        timeLockedSavings.withdraw(0);
        vm.stopPrank();
    }

    function testEmergencyWithdraw() public userDepositedSuccessfully(user1) {
        vm.startPrank(owner);
        timeLockedSavings.emergencyWithdraw(0, user1);
        vm.stopPrank();
        assertEq(payable(user1).balance, DEPOSIT_AMOUNT);
    }

    function testEmergencyWithdrawNotOwner() public userDepositedSuccessfully(user1) {
        vm.expectRevert(abi.encodeWithSelector(TimeLockedSavingsLibrary.NOT__OWNER.selector, user1, owner));
        vm.startPrank(user1);
        timeLockedSavings.emergencyWithdraw(0, user1);
        vm.stopPrank();
    }

    function testEmergencyWithdrawBadReceiver() public userDepositedSuccessfully(badReceiver) {
        vm.expectRevert();
        vm.startPrank(owner);
        timeLockedSavings.emergencyWithdraw(0, badReceiver);
        vm.stopPrank();
    }

    // Branches: bad receiver, withdraw too early, emergencyWithdraw with or without owner
}
