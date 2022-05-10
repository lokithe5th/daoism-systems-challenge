// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title  BalancerPoolToken
/// @author lourenslinde || LokiThe5th
/// @dev    This is a dummy contract to simulate the ERC20 Balancer Pool Tokens received on a .join call to a Balancer Pool
/// @dev    Because Balancer Pools issue tokens on join to represent a stake in the pool joined, a lightweight...
/// @dev    ...ERC20 implementation can be used to represent stakes in a Balancer Pool for testing purposes.

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BalancerPoolToken is ERC20 {

    /// @param  recipient1:address which receives majority of tokens representing stake in Balancer Pool
    /// @param  recipient2:address which receives minority stake in Balancer Pool
    constructor(address recipient1, address recipient2) ERC20("BalancerPoolToken", "BPT") {
        _mint(recipient1, 1000 * 10 ** decimals());
        _mint(recipient2, 900 * 10 ** decimals());
        
    }

}