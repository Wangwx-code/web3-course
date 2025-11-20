// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Reverse {
    function reverse(string memory str) public pure returns(string memory) {
        bytes memory raw = bytes(str);
        uint len = raw.length;
        bytes memory rev = new bytes(len);
        for (uint i = 0; i < len; i++) {
            rev[len - i - 1] = raw[i];
        }
        return string(rev);
    }
}