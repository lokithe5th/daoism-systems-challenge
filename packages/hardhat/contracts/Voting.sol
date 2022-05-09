pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

/// @title  Voting App
/// @author @lourenslinde
/// @notice Allows addresses which have a stake in Balancer pool to vote on proposed add/remove actions on GnosisSafe
/// @dev    

//Preferred method of making calls, but to allow arbitrary proposal execution
interface IGnosis {
    function getOwners() external;
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;
    function removeOwner(address owner, uint256 _threshold) external;
    function getPrevOwner(address _ownerToBeRemoved) external; 
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract Voting {

    address public safeAddress;
    IERC20 public balancerPoolToken;

    struct Proposal {
        address target;    //  name of proposal
        uint256 action;    //  0 -> addSigner, 1 -> removeSigner, 2 -> arbitrary tx
        uint256 voteCount;  //  number of votes (taking into account weighting)
        uint256 value;
        bytes proposal;
        bool passed;      //  false -> not executed, true -> already executed
        bool voteEnded;
    }

    //  Mapping of index => address => weight
    mapping(uint256 => mapping(address => uint256)) public votesByProposalIndexByStaker;
    mapping(uint256 => uint256) public votesForProposalByIndex;
    mapping(uint256 => uint256) public votesAgainstProposalByIndex;

    Proposal[] public proposals;

    /// @notice Votes for a given proposal
    /// @dev    Only stakers may vote, if passed a proposal will be executed
    /// @param  proposalIndex:uint256 The index of the proposal being voted on 
    /// @return bool true if passed, false if failed
    function vote(uint256 proposalIndex, uint8 voteType) public onlyStakers(msg.sender) returns (bool) {
        require(proposalIndex < proposals.length, "Invalid proposalIndex");
        require(voteType < 2, "Invalid voteType");
        require(votesByProposalIndexByStaker[proposalIndex][msg.sender]== 0, "Already voted");
        
        if (voteType == 0) {
            votesByProposalIndexByStaker[proposalIndex][msg.sender] = balancerPoolToken.balanceOf(msg.sender);
            votesForProposalByIndex[proposalIndex] = balancerPoolToken.balanceOf(msg.sender);
            console.logUint(votesForProposalByIndex[proposalIndex]);
        } else {
            votesByProposalIndexByStaker[proposalIndex][msg.sender] = balancerPoolToken.balanceOf(msg.sender);
            votesAgainstProposalByIndex[proposalIndex] = balancerPoolToken.balanceOf(msg.sender);
            console.logUint(votesAgainstProposalByIndex[proposalIndex]);
        }
        
        //  If total votes > 50% of stakers then execute the proposal 
        if (votesForProposalByIndex[proposalIndex] > (balancerPoolToken.totalSupply()/2)) {
            console.log("In Vote => Execution logic");
            executeProposal(proposalIndex, proposals[proposalIndex].value);
            proposals[proposalIndex].passed = true;
            
            return true;
        } else if (votesAgainstProposalByIndex[proposalIndex] > (balancerPoolToken.totalSupply()/2)) {
            proposals[proposalIndex].voteEnded = true;
        }

        return false;
    }

    /* @notice Submits a proposal for adding an address to GnosisSafe
    /// @dev 
    /// @param  proposedSigner:address The address to be added to the GnosisSafe
    function proposeAddSigner(address proposedSigner, uint256 threshold) public {
        bytes memory proposalPacked = abi.encode("addOwnerWithThreshold(address, uint256),",proposedSigner,",",threshold);
        proposals.push(Proposal({
            nominee: proposedSigner,
            action: 0,
            voteCount: 0,
            proposal: proposalPacked,
            executed: false
        }));

    }

    function proposeRemoveSigner(address proposedRemove, uint256 _threshold) public {
        bytes memory proposalPacked = abi.encode("removeOwner(address, uint256),",proposedRemove,",",_threshold);
        proposals.push(Proposal({
            nominee: proposedRemove,
            action: 1,
            voteCount: 0,
            proposal: proposalPacked,
            executed: false
        }));
    } */

    function submitProposal(
        address target, 
        uint256 threshold, 
        uint256 actionType, 
        uint256 proposalValue, 
        bytes memory proposalBytes
        ) public returns (uint256) {
            bytes memory proposalPacked;
            require(actionType < 4, "Invalid action");
            if (actionType == 0) {
                proposalPacked = abi.encodePacked("addOwnerWithThreshold(address, uint256),",target,",",threshold);
            } else if (actionType == 2) {
                proposalPacked = abi.encodePacked("removeOwner(address, uint256),",target,",",threshold);
            } else {
                proposalPacked = abi.encode(proposalBytes);
            }
         
            proposals.push(Proposal({
                target: target,
                action: actionType,
                voteCount: 0,
                value: proposalValue,
                proposal: proposalPacked,
                passed: false,
                voteEnded: false
            }));
            console.log("Proposal submitted");
            return proposals.length - 1;
    }

    /*
    function executeAddSigner(uint256 proposalIndex, uint256 _threshold) public {
        IGnosis(safeAddress).addOwnerWithThreshold(proposals[proposalIndex].nominee, _threshold);
    }

    function executeRemoveSigner(uint256 proposalIndex, uint256 _threshold, address prevOwner) public {
        IGnosis(safeAddress).removeOwner(prevOwner, proposals[proposalIndex].nominee, _threshold);
    }
    */

    function executeProposal(
        uint256 proposalIndex, 
        uint256 value
        ) 
        internal returns (bool) 
        {
            console.log("Starting execProp internal fx");
            require(!proposals[proposalIndex].voteEnded, "already ended");
            if (proposals[proposalIndex].action == 0) {
                IGnosis(safeAddress).addOwnerWithThreshold(proposals[proposalIndex].target, 1);
                proposals[proposalIndex].voteEnded = true;
                return true;
            } else if (proposals[proposalIndex].action == 1) {
                IGnosis(safeAddress).removeOwner(proposals[proposalIndex].target, 1);
                proposals[proposalIndex].voteEnded = true;
                return true;
            } 
            
            (bool success, bytes memory result) = proposals[proposalIndex].target.call{value: value}(proposals[proposalIndex].proposal);
            require(success, "execution failed");
            proposals[proposalIndex].voteEnded = true;
            console.log("Ending execProp internal fx");
            return true;
    }

    constructor(address _bpt, address _safeAddress) {
        setBalancerPoolToken(_bpt);
        safeAddress = _safeAddress;
    }

    function setSafeAddress(address _safeAddress) public {
        safeAddress = _safeAddress;
        console.logAddress(safeAddress);
    }

    function setBalancerPoolToken(address _bpt) public {
        balancerPoolToken = IERC20(_bpt);
        console.logAddress(address(balancerPoolToken));
    }

    modifier onlyStakers(address _voter) {
        require(balancerPoolToken.balanceOf(_voter) > 0,"not a staker");
        _;
    }

}