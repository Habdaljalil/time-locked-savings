// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployTimeLockedSavings} from "../../script/DeployTimeLockedSavings.s.sol";
import {TimeLockedSavings} from "../../src/TimeLockedSavings.sol";
import {TimeLockedSavingsLibrary} from "../../src/TimeLockedSavingsLibrary.sol";
import {console} from "forge-std/console.sol";

contract TestTimeLockedSavings is Test {
    TimeLockedSavings timeLockedSavings;
    address internal owner = makeAddr("Hassan");
    address internal user1 = makeAddr("User 1");
    uint256 constant DEPOSIT_AMOUNT = 5 ether;
    uint256 constant DURATION = 1 minutes;

    function setUp() public {
        DeployTimeLockedSavings deployTimeLockedSavings = new DeployTimeLockedSavings();
        timeLockedSavings = deployTimeLockedSavings.run(owner);
    }

    modifier userOneDepositedSuccessfully() {
        vm.deal(user1, DEPOSIT_AMOUNT);
        vm.startPrank(user1);
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

    function testWithdraw() public userOneDepositedSuccessfully {
        skip(DURATION);
        vm.expectEmit(true, true, true, false);
        emit TimeLockedSavingsLibrary.Withdraw(user1, vm.getBlockTimestamp(), DEPOSIT_AMOUNT);
        vm.startPrank(user1);
        timeLockedSavings.withdraw(0);
        vm.stopPrank();
    }

    function testWithdrawNonExistant() public userOneDepositedSuccessfully {
        vm.expectRevert(abi.encodeWithSelector(TimeLockedSavingsLibrary.DEPOSIT__DOES__NOT__EXIST.selector, 1));
        vm.startPrank(user1);
        timeLockedSavings.withdraw(1);
        vm.stopPrank();
    }

    function testWithdrawNoDeposits() public {
        vm.expectRevert(TimeLockedSavingsLibrary.NO__DEPOSITS.selector);
        vm.startPrank(user1);
        timeLockedSavings.withdraw(0);
        vm.stopPrank();
    }

    // Branches: bad receiver, withdraw too early, emergencyWithdraw with or without owner
}
