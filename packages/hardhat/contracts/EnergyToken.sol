// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title EnergyToken
/// @author lourenslinde || LokiThe5th

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EnergyToken is ERC20 {

    constructor(address recipient) ERC20("WorldEnergy", "ENRGY") {
        _mint(recipient, 1000 * 10 ** decimals());
        _mint(0x507bD2EA0737394A2d859E10A0FA192C3d32E627, 900 * 10 ** decimals());
        
    }

}