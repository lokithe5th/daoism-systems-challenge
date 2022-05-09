pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

/// @title  Voting App
/// @author @lourenslinde
/// @notice Allows addresses which have a stake in Balancer pool to vote on proposed add/remove actions on GnosisSafe
/// @dev    **NOT FOR PRODUCTION USE** 
/// @dev    This contract is part of a technical challenge for Daoism Systems, it has not been audited.

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
        address target;     // Address to be removed, added, or called
        uint8 action;       // 0 -> addSigner, 1 -> removeSigner, 2 -> arbitrary tx
        uint256 voteCount;  // Number of votes cast
        uint256 value;      // Value to be paid, 0 for action == 0 || == 1
        bytes proposal;     // Bytes representation of proposal, 0x30 if action == 0 || == 1
        bool passed;        // false -> unsuccessful, true -> successfull and executed
        bool voteEnded;     // Vote has ended. If voteEnded == true && passed == false, vote was unsuccessful
    }

    //  Mapping of index => address => weight
    mapping(uint256 => mapping(address => uint256)) public votesByProposalIndexByStaker;
    mapping(uint256 => uint256) public votesForProposalByIndex;
    mapping(uint256 => uint256) public votesAgainstProposalByIndex;

    Proposal[] public proposals;

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
                executeProposal(proposalIndex);
                proposals[proposalIndex].passed = true;

                return true;
            } else if (votesAgainstProposalByIndex[proposalIndex] > (balancerPoolToken.totalSupply()/2)) {
                proposals[proposalIndex].voteEnded = true;
            }

            return false;
        }

    /// @notice Proposal submission
    /// @dev    Creates a Proposal struct which is added to the proposals array
    /// @param  target:address to be added, removed or called
    /// @param  threshold:uint8, the new threshold for Gnosis Safe
    /// @param  actionType:uint8, if == 0 {add target to safe}, if == 1 {remove target from safe}, else execute arbitrary proposal
    /// @param  proposalValue:uint256, Value to be sent with call. Should be 0 for actionTypes 0 || 1
    /// @param  proposalBytes:bytes, Encoded proposal for arbitrary call execution
    /// @return uint256 The newly submitted proposal's index
    function submitProposal(
        address target, 
        uint8 threshold, 
        uint8 actionType, 
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

    /// @notice Executes a proposal once vote > 50% of totalSupply
    /// @param  proposalIndex:uint256, index of the proposal to be executed
    function executeProposal(
        uint256 proposalIndex
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
            
            (bool success, bytes memory result) = proposals[proposalIndex].target.call{value: proposals[proposalIndex].value}(proposals[proposalIndex].proposal);
            require(success, "execution failed");
            proposals[proposalIndex].voteEnded = true;
            console.log("Ending execProp internal fx");
            return true;
        }

    //  Setup of the balancer pool token to be tracked and the Gnosis Safe to be controlled
    constructor(
        address _bpt, 
        address _safeAddress) {
            safeAddress = _safeAddress;
            balancerPoolToken = IERC20(_bpt);
        }

    /// Modifier to only allow stakers (who are represented by holding balancer pool tokens) to call functions
    modifier onlyStakers(address _voter) {
        require(balancerPoolToken.balanceOf(_voter) > 0,"not a staker");
        _;
    }

}