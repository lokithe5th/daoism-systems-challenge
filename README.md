
# daoism-systems-challenge

This repo contains the completed code for the backend/smart contracts portion of the Daoism Systems technical challenge.

## introduction  

The contracts were developed with scaffold-eth to enable faster prototyping and reduce development time. This approach allows easy installation on a local machine. 

To install and run the contracts and front end locally:  
`yarn install`  
`yarn run`
`yarn chain`  
`yarn deploy`  

## Voting App  

The main logic of this app is located in Voting.sol; it holds the logic for 1) making proposals, 2) voting on proposals, 3) to execute token-gated, stake-weighted, predefined addOwner and removeOwner funtions through interfacing with a custom Gnosis Safe implementation 4) recording a history of proposals and votes made for and against those proposals.  

The Gnosis Safe implementation has two differences compared to the conventional implementation.  

Firstly, the "authorized" modifier has been removed from "OwnerManager.sol" to allow the Voting contract to add/remove Owners to the Gnosis Safe.  

Secondly, an additional function, "getPrevOwner(address)", has been added to the "OwnerManager.sol" contract. This allows for the contract to determine the previousOwner in the linked list that tracks Safe owners; in this way Owners can be removed without requiring the front-end to have knowledge of the owner that pointed to the address to be removed.  

The contract BalancerPoolToken.sol is a simple ERC20 token implementation. The Voting App should be linked to a Balancer Pool, but on a local machine it is less cumbersome to link the Voting App to the lightweight ERC20 token. As a Weighted Balancer Pool represents a participant's stake through an issued balancer pool token (as an ERC20), the behaviour should be the same if safeAddress is set to a custom balancer pool. 

## Happy Path Simulation  

The happy path simulation can be run through `yarn test`. The flow can be represented by submit "addOwner" proposal, vote "for" proposal[0], execute "addOwner", return the array of owners from the Safe (two members), submit "removeOwner" proposal, vote "for" proposal[1], remove Owner from Safe and retrieve array with one member.  

## Testnet Deployment  

The verified contracts can be found on the Rinkeby testnet.  

[Voting.sol]()  
[GnosisSafe.sol]()  
[BalancerPoolToken.sol]()  

