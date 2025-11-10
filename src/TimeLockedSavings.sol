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

        require(numberOfUserDeposits > 0, TimeLockedSavingsLibrary.NO__DEPOSITS());
        if (depositId > numberOfUserDeposits - 1) {
            revert TimeLockedSavingsLibrary.DEPOSIT__DOES__NOT__EXIST(depositId);
        }
    }

    function deposit(uint256 duration) external payable {
        require(msg.value > 0, TimeLockedSavingsLibrary.NOT__ENOUGH__FUNDS(msg.value));
        require(duration > 0, TimeLockedSavingsLibrary.NOT__ENOUGH__TIME(duration));
        userToDeposits[msg.sender].push(
            TimeLockedSavingsLibrary.Deposit({amount: msg.value, unlockTime: duration, withdrawn: false})
        );
        emit TimeLockedSavingsLibrary.Deposited(msg.sender, block.timestamp, msg.value);
    }

    function withdraw(uint256 depositId)
        external
        payable
        depositExists(depositId, msg.sender)
        returns (bool callSuccess)
    {
        TimeLockedSavingsLibrary.Deposit storage userDeposit = userToDeposits[msg.sender][depositId];
        if (block.timestamp >= userDeposit.unlockTime) {
            (bool withdrawSuccess,) = address(msg.sender).call{value: userDeposit.amount}("Standard Withdraw");
            require(withdrawSuccess);
            emit TimeLockedSavingsLibrary.Withdraw(msg.sender, block.timestamp, userDeposit.amount);
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

    function getOwner() external view returns (address) {
        return I_OWNER;
    }

    function getUserToDeposits(address user) external view returns (TimeLockedSavingsLibrary.Deposit[] memory) {
        return userToDeposits[user];
    }
}
