// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract BinarySearch {
    function binarySearch(int[] calldata arr, int target) external pure returns (int) {
        uint i = 0;
        uint j = arr.length - 1;
        while (i <= j) {
            uint k = (i + j) / 2;
            int mid = arr[k];
            if (target == mid) {
                return int(k);
            } else if (target < mid) {
                j = k - 1;
            } else {
                i = k + 1;
            }
        }
        return -1;
    }
}