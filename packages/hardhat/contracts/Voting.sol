pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

/// @title  Voting App
/// @author @lourenslinde
/// @notice Allows addresses which have a stake in Balancer pool to vote on proposed add/remove actions on GnosisSafe
/// @dev    

interface IGnosis {
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;
    function removeOwner(address prevOwner, address owner, uint256 _threshold) external; 
}

contract Voting {

    address public safeAddress;

    struct Voter {
        bool voted;     // has voted
        uint256 vote;   // tracks index of proposal voted for
    }

    struct Proposal {
        address nominee;    //  name of proposal
        uint256 action;    //  0 -> addSigner, 1 -> removeSigner, 2 -> arbitrary tx
        uint256 voteCount;  //  number of votes (taking into account weighting)
        bytes proposal;
        bool executed;      //  false -> not executed, true -> already executed
    }

    // Is this needed? Can an address not be checked when voting?
    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    modifier onlyStakers(address voter) {
        // TO DO
        require(1>0,"not a staker");
        _;
    }

    /// @notice Votes for a given proposal
    /// @dev    Only stakers may vote, if passed a proposal may be executed
    /// @param  index:uint256 The index of the proposal being voted on 
    /// @return bool true if passed, false if failed
    function vote(uint256 index) public onlyStakers(msg.sender) returns (bool) {

    }

    /// @notice Submits a proposal for adding an address to GnosisSafe
    /// @dev 
    /// @param  proposedSigner:address The address to be added to the GnosisSafe
    function proposeAddSigner(address proposedSigner, uint256 threshold) public {
        bytes memory proposalPacked = abi.encodePacked("addOwnerWithThreshold(address, uint256),",proposedSigner,",",threshold);
        proposals.push(Proposal({
            nominee: proposedSigner,
            action: 0,
            voteCount: 0,
            proposal: proposalPacked,
            executed: false
        }));

    }

    function proposeRemoveSigner(address proposedRemove, uint256 _threshold) public {
        bytes memory proposalPacked = abi.encodePacked("removeOwner(address, uint256),",proposedRemove,",",_threshold);
        proposals.push(Proposal({
            nominee: proposedRemove,
            action: 1,
            voteCount: 0,
            proposal: proposalPacked,
            executed: false
        }));
    }

    function executeAddSigner(uint256 proposalIndex, uint256 _threshold) public {
        IGnosis(safeAddress).addOwnerWithThreshold(proposals[proposalIndex].nominee, _threshold);
    }

    function executeRemoveSigner(uint256 proposalIndex, uint256 _threshold, address prevOwner) public {
        IGnosis(safeAddress).removeOwner(prevOwner, proposals[proposalIndex].nominee, _threshold);
    }

    function executeProposal(uint256 proposalIndex, address safe, uint256 value) public returns (bytes memory) {
        require(!proposals[proposalIndex].executed, "already executed");
        (bool success, bytes memory result) = safe.call{value: value}(proposals[proposalIndex].proposal);
        require(success, "execution failed");
        return result;
    }

    constructor() {

    }

}