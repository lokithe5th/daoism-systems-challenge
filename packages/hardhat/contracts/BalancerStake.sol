pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract BalancerStake {
    IERC20 public balancerPoolToken;

    function setBalancerPoolToken(address _bpt) internal {
        balancerPoolToken = IERC20(_bpt);
    }

}
