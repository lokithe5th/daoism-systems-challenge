
# daoism-systems-challenge

This repo contains the completed code for the backend/smart contracts portion of the Daoism Systems technical challenge.

## Introduction  

The contracts were developed with scaffold-eth to enable faster prototyping and reduce development time. This approach allows easy installation on a local machine. 

To install and run the contracts and front end locally:  
`yarn install`  
`yarn run`  
`yarn chain`  
`yarn deploy`  

## Voting App  

### Voting.sol

The main logic of this app is located in Voting.sol; it holds the logic for 1) making proposals, 2) voting on proposals, 3) to execute token-gated, stake-weighted and predefined addOwner and removeOwner funtions through interfacing with a custom Gnosis Safe implementation 4) recording a history of proposals and votes made for and against those proposals.  

It must be noted that, to decrease front-end interaction requirements, once a proposal's votes are more than 50% of the pool token totalSupply, the proposal will be automatically executed. Any voting app like this can be manipulated by buying a majority of the pool tokens and forcing any proposal to be voted on to be passed. Vulnerability against Flash Attacks may exist. *This is merely a technical challenge submission and not for production deployment.* 

`submitProposal(address target, uint8 threshold, uint8 actionType, uint256 proposalValue, string memory proposal)`  

address: the address to be added or removed  

threshold: the new signer threshold for the Safe  

actionType: if 0 then addOwner execution path will be called once vote passes, if 1 then removeOwner execution path will be followed  

proposalValue: usually 0, unless functions need to be payable  

proposal: short description of proposal  

`vote(uint256 proposalIndex, uint8 voteType)`  

proposalIndex: the index identifying the proposal to be voted on  

voteType: if 0, vote is "yes/for"; if 1, vote is "no/against"

### GnosisSafe.sol  

The Gnosis Safe implementation has two differences compared to the conventional implementation.  

Firstly, the "authorized" modifier has been removed from "OwnerManager.sol" to allow the Voting contract to add/remove Owners to the Gnosis Safe.  

Secondly, an additional function, "getPrevOwner(address)", has been added to the "OwnerManager.sol" contract. This allows for the contract to determine the previousOwner in the linked list that tracks Safe owners; in this way Owners can be removed without requiring the front-end to have knowledge of the owner that pointed to the address to be removed.  

### BalancerPoolToken.sol

The contract BalancerPoolToken.sol is a simple ERC20 token implementation. The Voting App should be linked to a Balancer Pool, but on a local machine it is less cumbersome to link the Voting App to the lightweight ERC20 token. As a Weighted Balancer Pool represents a participant's stake through an issued balancer pool token (as an ERC20), the behaviour should be the same if safeAddress is set to a custom balancer pool. 

## Happy Path Simulation  

The happy path simulation can be run through `yarn test`. The flow can be represented by submit "addOwner" proposal -> vote "for" proposal[0] -> execute "addOwner" -> return the array of owners from the Safe (two members) -> submit "removeOwner" proposal -> vote "for" proposal[1] -> remove Owner from Safe -> retrieve array with the one remaining member.  

## Testnet Deployment  

The verified contracts can be found on the Rinkeby testnet.  

[Voting.sol](https://rinkeby.etherscan.io/address/0x6e88527e1144E93A85Ac02caeeFB99e356950568#code)  
[GnosisSafe.sol](https://rinkeby.etherscan.io/address/0xB6339f598637Da7f94d63fa422BD8888dCddbEB6#code)  
[BalancerPoolToken.sol](https://rinkeby.etherscan.io/address/0xA9a7C8461f3F5DA503Cd0778Ff511CeB3d10c77B#code)  

## Acknowledgements  

This submission used scaffold-eth which provides a solid foundation for fast contract development and iteration. [The main scaffold-eth Github repo can be found here](https://github.com/scaffold-eth/scaffold-eth).  


