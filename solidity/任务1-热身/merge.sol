// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
contract Merge{

    function merge(int[] memory arr1, int[] memory arr2) pure public returns(int[] memory){
        uint i = 0;
        uint j = 0;
        uint k = 0;
        int[] memory result = new int[](arr1.length + arr2.length);
        while (i < arr1.length && j < arr2.length) {
            int a = arr1[i];
            int b = arr2[j];
            if (a < b) {
                result[k] = a;
                i++;
            } else {
                result[k] = b;
                j++;
            }
            k++;
        }
        while (i < arr1.length) {
            result[k] = arr1[i];
            k++;
            i++;
        }
        while (j < arr2.length) {
            result[k] = arr1[j];
            k++;
            j++;
        }
        return result;
    }
}