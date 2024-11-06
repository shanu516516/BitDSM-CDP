// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IBitcoinPod} from "../interfaces/IBitcoinPod.sol";
contract MockBitcoinPod is IBitcoinPod {
    bool public locked;

    function getBitcoinAddress() external pure returns (bytes memory) {
        return "";
    }

    function getOperatorBtcPubKey() external pure returns (bytes memory) {
        return "";
    }

    function getOperator() external pure returns (address) {
        return address(0);
    }

    function getBitcoinBalance() external pure returns (uint256) {
        return 0;
    }

    function lock() external {
        locked = true;
    }

    function unlock() external {
        locked = false;
    }

    function isLocked() external view returns (bool) {
        return locked;
    }

    function mint(address, uint256) external pure {}

    function burn(address, uint256) external pure {}
}
