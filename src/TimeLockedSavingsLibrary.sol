// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.30;

library TimeLockedSavingsLibrary {
    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    /// Events
    event Deposited(address indexed user, uint256 indexed timestamp, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed timestamp, uint256 amount);
    // These could be merged into one event

    /// Errors

    error NOT__OWNER(address sender, address owner);
    error DEPOSIT__DOES__NOT__EXIST(uint256 depositId);
    error WITHDRAW__TOO__EARLY(uint256 timestamp);
    error NOT__ENOUGH__FUNDS(uint256 funds);
    error NOT__ENOUGH__TIME(uint256 time);
    error NO__DEPOSITS();
}
