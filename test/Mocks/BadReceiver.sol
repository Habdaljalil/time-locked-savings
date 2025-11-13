// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.30;

contract BadReceiver {
    error CANNOT__RECEIVE();

    fallback() external payable {
        revert CANNOT__RECEIVE();
    }
}
