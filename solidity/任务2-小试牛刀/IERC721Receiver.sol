// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
// ERC721接收器接口
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
