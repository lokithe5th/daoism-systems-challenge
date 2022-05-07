pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract Voting {

    struct Voter {
        uint256 weight; // weight is determined through stake in balancer pool
        bool voted;     // has voted
        uint256 vote;   // tracks index of proposal voted for
    }

    struct Proposal {
        bytes32 name;       // name of proposal
        uint256 voteCount;  // number of votes (taking into account weighting)
    }

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    constructor() {
        
    }

}