// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.30;

import {TimeLockedSavingsLibrary} from "./TimeLockedSavingsLibrary.sol";

contract TimeLockedSavings {
    mapping(address => TimeLockedSavingsLibrary.Deposit[]) userToDeposits;

    address immutable I_OWNER;

    constructor() {
        I_OWNER = msg.sender;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != I_OWNER) {
            revert TimeLockedSavingsLibrary.NOT__OWNER(msg.sender, I_OWNER);
        }
    }

    modifier depositExists(uint256 depositId, address user) {
        _depositExists(depositId, user);
        _;
    }

    function _depositExists(uint256 depositId, address user) internal view {
        uint256 numberOfUserDeposits = userToDeposits[user].length;

        require(numberOfUserDeposits > 0);
        if (depositId > numberOfUserDeposits - 1) {
            revert TimeLockedSavingsLibrary.DEPOSIT__DOES__NOT__EXIST(depositId);
        }
    }

    function deposit(uint256 duration) external payable {
        require(msg.value > 0);
        userToDeposits[msg.sender].push(
            TimeLockedSavingsLibrary.Deposit({amount: msg.value, unlockTime: duration, withdrawn: false})
        );
        emit TimeLockedSavingsLibrary.Deposited(msg.sender, block.timestamp, msg.value);
    }

    function withdraw(uint256 depositId)
        public
        payable
        depositExists(depositId, msg.sender)
        returns (bool callSuccess)
    {
        // public because emergency calls it
        TimeLockedSavingsLibrary.Deposit storage userDeposit = userToDeposits[msg.sender][depositId];
        if (block.timestamp >= userDeposit.unlockTime) {
            (bool withdrawSuccess,) = address(msg.sender).call{value: userDeposit.amount}("Standard Withdraw");
            require(withdrawSuccess);
            return withdrawSuccess;
        } else {
            revert TimeLockedSavingsLibrary.WITHDRAW__TOO__EARLY(block.timestamp);
        }
    }

    function emergencyWithdraw(uint256 depositId, address user)
        external
        onlyOwner
        depositExists(depositId, user)
        returns (bool callSuccess)
    {
        TimeLockedSavingsLibrary.Deposit storage userDeposit = userToDeposits[user][depositId];

        (bool emergencyWithdrawSuccess,) = address(user).call{value: userDeposit.amount}("Emergency Withdraw");
        require(emergencyWithdrawSuccess);
        return emergencyWithdrawSuccess;
    }
}
