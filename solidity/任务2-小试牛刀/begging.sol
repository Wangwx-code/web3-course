// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Begging {
    mapping (address => uint256) private _donations;
    address[] private _donaters;
    address[] private _rank;

    address private _owner;
    uint256 private _endtime;

    constructor(uint256 duration) {
        _owner = msg.sender;
        _endtime = block.timestamp + duration;
    }

    event Donation(address indexed donater, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function isEnd() public view returns (bool) {
        return block.timestamp > _endtime;
    }

    function donate() external payable {
        require(!isEnd());
        require(msg.value > 0);
        address donater = msg.sender;
        uint256 amount = msg.value;
        if (_donations[donater] == 0) {
            _donaters.push(donater);
        }
        _addRank(donater, amount);
        _donations[donater] += amount;
    }

    function _addRank(address donater, uint256 amount) private {
        if (_rank.length < 3) {
            if (_donations[donater] == 0) {
                _rank.push(donater);
            }
        } else if (_donations[_rank[0]] < amount) {
            _rank[0] = donater;
        }
        _adjust();
    }

    function _adjust() private {
        if (_rank.length < 2) return;
        (_rank[0], _rank[1]) = _swap(_rank[0], _rank[1]);
        if (_rank.length < 3) return;
        (_rank[0], _rank[2]) = _swap(_rank[0], _rank[2]);
    }

    function _swap(address a, address b) private view returns(address, address) {
        if (_donations[a] < _donations[b]) {
            return (a, b);
        } else {
            return (b, a);
        }
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send ETH");
    }

    function getDonation(address account) external view returns (uint256) {
        return _donations[account];
    }

    function getRank() external view returns (address[] memory) {
        return _rank;
    }

}