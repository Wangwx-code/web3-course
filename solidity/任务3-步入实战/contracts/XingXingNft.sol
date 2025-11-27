// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract XingXingNft is ERC721("XingXing", "xx") {
    uint256 private _mintId = 1;

    function mint() external {
        _safeMint(msg.sender, _mintId);
        _mintId++;
    }
}