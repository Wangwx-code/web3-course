// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Voting {
    struct Voter {
        bool hasVoted;
        uint32 voteIndex;
    }

    struct Candidate {
        string name;
        uint256 count;
    }

    address[] public candidates;
    mapping(address => Candidate) canInfo;
    mapping(address => Voter) voterInfo;

    uint256 public endTime;

    constructor (address[] memory cans, string[] memory names, uint32 duration) {
        require(cans.length > 0, "candidates can not be empty");
        require(cans.length == names.length, "candidates length != names length");
        require(duration > 10, "duration must larger than 10");
        candidates = cans;
        for (uint i = 0; i < cans.length; i++) {
            address canAddr = cans[i];
            canInfo[canAddr].name = names[i];
        }
        endTime = block.timestamp + (duration * 1 seconds);
    }

    function vote(uint32 index) external {
        require(block.timestamp <= endTime);
        require(index < candidates.length);
        address addr = msg.sender;
        require(!voterInfo[addr].hasVoted);
        voterInfo[addr].hasVoted = true;
        voterInfo[addr].voteIndex = index;
        address canAddr = candidates[index];
        canInfo[canAddr].count++;
    }

    function getVote(uint32 index) public view returns (uint256){
        require(index < candidates.length);
        return canInfo[candidates[index]].count;
    }

    function getResult() external view returns (string memory, uint256) {
        require(block.timestamp > endTime);
        uint32 maxIndex = 0;
        uint256 maxNum = getVote(0);
        for (uint32 i = 1; i < candidates.length; i++) {
            uint256 num = getVote(i);
            if (num > maxNum) {
                maxIndex = i;
                maxNum = num;
            }
        }
        return (canInfo[candidates[maxIndex]].name, maxNum);
    }
}