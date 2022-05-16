pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

/// @title  Voting App
/// @author @lourenslinde
/// @notice Allows addresses which have a stake in Balancer pool to vote on proposed add/remove actions on GnosisSafe
/// @dev    **NOT FOR PRODUCTION USE** 
/// @dev    This contract is part of a technical challenge for Daoism Systems, it has not been audited.

//Preferred method of making calls
interface IGnosis {
    function getOwners() external;
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;
    function removeOwner(address owner, uint256 _threshold) external;
    function getPrevOwner(address _ownerToBeRemoved) external; 
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting {
    event newProposal(uint256 proposalIndex);
    event voted(uint256 proposalIndex, address voter, uint256 votes, uint8 voteType);
    event proposalPassed(uint256 proposalIndex);
    event proposalFailed(uint256 proposalIndex);
    event proposalExecuted(uint256 proposalIndex);
    event addSigner(address newSigner);
    event removeSigner(address removedSigner);

    address public safeAddress;
    IERC20 public balancerPoolToken;

    struct Proposal {
        address target;     // Address to be removed, added, or called
        uint8 action;       // 0 -> addSigner, 1 -> removeSigner, 2 -> arbitrary tx
        uint256 voteCount;  // Number of votes cast
        uint256 value;      // Value to be paid, 0 for action == 0 || == 1
        string proposal;    // String summary of proposal
        bool passed;        // false -> unsuccessful, true -> successfull and executed
        bool voteEnded;     // Vote has ended. If voteEnded == true && passed == false, vote was unsuccessful
    }

    //  Mapping of index => address => weight
    mapping(uint256 => mapping(address => uint256)) private votesByProposalIndexByStaker;
    mapping(uint256 => uint256) private votesForProposalByIndex;
    mapping(uint256 => uint256) private votesAgainstProposalByIndex;

    /// Array of Proposal structs
    Proposal[] public proposals;

    //  Setup of the balancer pool token to be tracked and the Gnosis Safe to be controlled
    constructor(
        address _bpt, 
        address _safeAddress) {
            safeAddress = _safeAddress;
            balancerPoolToken = IERC20(_bpt);
        }
    
    /// @notice Proposal submission
    /// @dev    Creates a Proposal struct which is added to the proposals array
    /// @param  target:address to be added, removed or called
    /// @param  threshold:uint8, the new threshold for Gnosis Safe
    /// @param  actionType:uint8, if == 0 {add target to safe}, if == 1 {remove target from safe}, else execute arbitrary proposal
    /// @param  proposalValue:uint256, Value to be sent with call. Should be the new threshold for actionTypes 0 || 1
    /// @param  proposal:string, description of proposal
    /// @return uint256 The newly submitted proposal's index
    function submitProposal(
        address target, 
        uint8 threshold, 
        uint8 actionType, 
        uint256 proposalValue, 
        string memory proposal
        ) public returns (uint256) {
            require(actionType < 3, "Invalid action");

            uint256 _value;
            if (actionType == 0 || actionType == 1) {
                _value = threshold;
            } else {
                _value = proposalValue;
            }
         
            proposals.push(Proposal({
                target: target,
                action: actionType,
                voteCount: 0,
                value: _value,
                proposal: proposal,
                passed: false,
                voteEnded: false
            }));

            emit newProposal(proposals.length-1);
            return (proposals.length - 1);
        }

    /// @notice Vote logic
    /// @dev    Only stakers may vote, if passed a proposal will be executed, action type determines execution path
    /// @param  proposalIndex:uint256 The index of the proposal being voted on 
    /// @return bool true if passed, false if failed
    function vote(
        uint256 proposalIndex, 
        uint8 voteType
        ) public onlyStakers(msg.sender) returns (bool) {
            require(proposalIndex < proposals.length, "Invalid proposalIndex");
            require(voteType < 2, "Invalid voteType");
            require(votesByProposalIndexByStaker[proposalIndex][msg.sender]== 0, "Already voted");
            require(!proposals[proposalIndex].voteEnded,"Vote has ended");
        
            //  Voting logic
            countVotes(proposalIndex, voteType);

            //  If total for votes >= 50% of stakers then execute the proposal 
            if (votesForProposalByIndex[proposalIndex] >= (balancerPoolToken.totalSupply()/2)) {
                require(executeProposal(proposalIndex), "execution failed");
                proposals[proposalIndex].passed = true;
                emit proposalPassed(proposalIndex);
                return true;
            //  If total against votes >50%, set voteEnded = true, passed remains false as per default value
            } else if (votesAgainstProposalByIndex[proposalIndex] > (balancerPoolToken.totalSupply()/2)) {
                proposals[proposalIndex].voteEnded = true;
                emit proposalFailed(proposalIndex);
                return false;
            }
            return false;
        }

    /// @notice Internal function for counting and allocating votes
    /// @param  proposalIndex Index of the proposal being voted on
    /// @param  voteType:uint8 representing the execution path to follow
    function countVotes(
        uint256 proposalIndex, 
        uint8 voteType
        ) internal {
            if (voteType == 0) {
                    votesByProposalIndexByStaker[proposalIndex][msg.sender] = balancerPoolToken.balanceOf(msg.sender);
                    votesForProposalByIndex[proposalIndex] = balancerPoolToken.balanceOf(msg.sender);
                } else {
                    votesByProposalIndexByStaker[proposalIndex][msg.sender] = balancerPoolToken.balanceOf(msg.sender);
                    votesAgainstProposalByIndex[proposalIndex] = balancerPoolToken.balanceOf(msg.sender);
                }

                emit voted(proposalIndex, msg.sender, balancerPoolToken.balanceOf(msg.sender), voteType);
    }

    /// @notice Executes a proposal once vote > 50% of totalSupply
    /// @param  proposalIndex:uint256, index of the proposal to be executed
    function executeProposal(
        uint256 proposalIndex
        ) 
        internal returns (bool) 
        {
            require(!proposals[proposalIndex].voteEnded, "already ended");
            if (proposals[proposalIndex].action == 0) {
                IGnosis(safeAddress).addOwnerWithThreshold(proposals[proposalIndex].target, proposals[proposalIndex].value);
                proposals[proposalIndex].voteEnded = true;
                return true;
            } else if (proposals[proposalIndex].action == 1) {
                IGnosis(safeAddress).removeOwner(proposals[proposalIndex].target, proposals[proposalIndex].value);
                proposals[proposalIndex].voteEnded = true;
                return true;
            } 
            
            return false;
        }

    /// @notice Returns the amount of votes for a given proposal index
    function getVotesForProposalByIndex(uint256 proposalIndex) public view returns (uint256) {
        return votesForProposalByIndex[proposalIndex];
    }

    /// @notice Returns the amount of votes against a given proposal index
    function getVotesAgainstProposalByIndex(uint256 proposalIndex) public view returns (uint256) {
        return votesForProposalByIndex[proposalIndex];
    }

    /// @notice Allows for tracking of votes by address and proposal index
    function getVotesByProposalIndexByStaker(uint256 proposalIndex, address voter) public view returns (uint256) {
        return votesByProposalIndexByStaker[proposalIndex][voter];
    }

    /// Modifier to only allow stakers (who are represented by holding balancer pool tokens) to call functions
    modifier onlyStakers(address _voter) {
        require(balancerPoolToken.balanceOf(_voter) > 0,"not a staker");
        _;
    }

}