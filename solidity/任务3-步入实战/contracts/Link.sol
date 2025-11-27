// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Link is ERC20 {
    constructor() ERC20("Chainlink", "Link") {
    }

    function mint(uint256 value) external {
        _mint(msg.sender, value * 10 ** 18);
    }
}