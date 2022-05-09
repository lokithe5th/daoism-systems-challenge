pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

/// @title  Voting App
/// @author @lourenslinde
/// @notice Allows addresses which have a stake in Balancer pool to vote on proposed add/remove actions on GnosisSafe
/// @dev    

/* Preferred method of making calls, but to allow arbitrary proposal execution
interface IGnosis {
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;
    function removeOwner(address prevOwner, address owner, uint256 _threshold) external; 
}*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting {

    address public safeAddress;
    IERC20 public balancerPoolToken;

    struct Proposal {
        address target;    //  name of proposal
        uint256 action;    //  0 -> addSigner, 1 -> removeSigner, 2 -> arbitrary tx
        uint256 voteCount;  //  number of votes (taking into account weighting)
        uint256 value;
        bytes proposal;
        bool executed;      //  false -> not executed, true -> already executed
    }

    //  Mapping of index => address => weight
    mapping(uint256 => mapping(address => uint256)) public votesByProposalIndexByStaker;
    mapping(uint256 => uint256) public votesByProposalIndex;

    Proposal[] public proposals;

    /// @notice Votes for a given proposal
    /// @dev    Only stakers may vote, if passed a proposal will be executed
    /// @param  proposalIndex:uint256 The index of the proposal being voted on 
    /// @return bool true if passed, false if failed
    function vote(uint256 proposalIndex) public onlyStakers(msg.sender) returns (bool) {
        require(proposalIndex < proposals.length, "Invalid proposalIndex");
        require(votesByProposalIndexByStaker[proposalIndex][msg.sender]== 0, "Already voted");
        votesByProposalIndex[proposalIndex] = votesByProposalIndex[proposalIndex] + (balancerPoolToken.balanceOf(msg.sender)/balancerPoolToken.totalSupply());
        //  If total votes > 50% of stakers then execute the proposal 
        if (votesByProposalIndex[proposalIndex] > (balancerPoolToken.totalSupply()/2)) {
            executeProposal(proposalIndex, proposals[proposalIndex].value);
            proposals[proposalIndex].executed = true;
            return true;
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
                proposalPacked = abi.encode("addOwnerWithThreshold(address, uint256),",target,",",threshold);
            } else if (actionType == 2) {
                proposalPacked = abi.encode("removeOwner(address, uint256),",target,",",threshold);
            } else {
                proposalPacked = abi.encode(proposalBytes);
            }
         
            proposals.push(Proposal({
                target: target,
                action: actionType,
                voteCount: 0,
                value: proposalValue,
                proposal: proposalPacked,
                executed: false
            }));

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
        public returns (bytes memory) 
        {
            require(!proposals[proposalIndex].executed, "already executed");
            (bool success, bytes memory result) = proposals[proposalIndex].target.call{value: value}(proposals[proposalIndex].proposal);
            require(success, "execution failed");
            return result;
    }

    constructor(address _safeAddress, address _bpt) {
        setBalancerPoolToken(_bpt);
        safeAddress = _safeAddress;
    }

    function setBalancerPoolToken(address _bpt) internal {
        balancerPoolToken = IERC20(_bpt);
    }

    modifier onlyStakers(address _voter) {
        require(balancerPoolToken.balanceOf(_voter) > 0,"not a staker");
        _;
    }

}