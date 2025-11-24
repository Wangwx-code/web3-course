// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "contracts/IERC721Receiver.sol";

contract MyNft {

    string private _name;
    string private _symbol;


    mapping (uint256 tokenId => address) private _owners;

    mapping (address owner => uint256) private _balances;

    mapping (uint256 tokenId => address) private _tokenApprovals;

    mapping (address owner => mapping (address operator => bool)) private _operatorApprovals;

    mapping (uint256 tokenId => string) _tokenCid;

    uint256 _mintId = 1;
    address _admin;

    // ERC721TokenReceiver 接口标识符
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // 事件
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    modifier onlyOwnerOrApproved(uint256 tokenId) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        require(
            msg.sender == owner ||
            msg.sender == _tokenApprovals[tokenId] ||
            _operatorApprovals[owner][msg.sender],
            "Not owner nor approved"
        );
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _admin = msg.sender;
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function baseTokenURI() private pure returns (string memory) {
        return "https://fuchsia-lazy-mite-451.mypinata.cloud/ipfs/";
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return string.concat(
            baseTokenURI(),
            _tokenCid[tokenId]
        );
    }

    function mint(string calldata cid) external {
        require(msg.sender == _admin);
        _mint(_admin, cid);
    }

    // 查询函数
    function balanceOf(address owner) external view returns (uint256 balance) {
        require(owner != address(0));
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        require(_owners[tokenId] != address(0));
        return _owners[tokenId];
    }

    // 授权函数
    function approve(address to, uint256 tokenId) external {
        _approve(msg.sender, to, tokenId);
        emit Approval(msg.sender, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address operator) {
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // 转账函数
    function transferFrom(address from, address to, uint256 tokenId) external {
        _transferFrom(from, to, tokenId);
        emit Transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        _transferFrom(from, to, tokenId);

        if (_isContract(to)) {
            bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
            require(retval == _ERC721_RECEIVED);
        }

        emit Transfer(from, to, tokenId);
    }

    function _isContract(address account) private view returns(bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _mint(address owner, string calldata cid) private {
        _addToken(owner, _mintId);
        _tokenCid[_mintId] = cid;
        _mintId++;
    }

    function _burn(address owner, uint256 tokenId) private {
        _deleteToken(owner, tokenId);
    }

    function _deleteToken(address owner, uint256 tokenId) private {
        require(_owners[tokenId] == owner);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _tokenApprovals[tokenId];
    }

    function _addToken(address owner, uint256 tokenId) private {
        _balances[owner] += 1;
        _owners[tokenId] = owner;
    }

    function _transferFrom(address from, address to, uint256 tokenId) onlyOwnerOrApproved(tokenId) private {
        _update(from, to, tokenId);
    }

    function _update(address from, address to, uint256 tokenId) private {
        require(from != address(0) || to != address(0));
        if (from == address(0)) {
            revert();
        }
        if (to == address(0)) {
            _burn(from, tokenId);
            return;
        }
        require(_owners[tokenId] == from);
        _deleteToken(from, tokenId);
        _addToken(to, tokenId);
    }

    function _approve(address owner, address operator, uint256 tokenId) private {
        require(msg.sender == owner);
        require(_owners[tokenId] == owner);
        _tokenApprovals[tokenId] = operator;
    }

    function _setApprovalForAll(address owner, address operator, bool approved) private {
        require(msg.sender == owner);
        require(owner != address(0));
        _operatorApprovals[owner][operator] = approved;
    }
}


