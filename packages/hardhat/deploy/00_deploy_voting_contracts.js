// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

// **Change these addresses to the local testing browser addresses**
const testingStakeHolders = ["0x9BB09321140d2Ed471867bE56b5D5936BAB93E85","0x507bD2EA0737394A2d859E10A0FA192C3d32E627"];

const localChainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  await deploy("GnosisSafe", {
    from: deployer,
    log: true,
    waitConfirmations: 5,
  });

  const GnosisSafe = await ethers.getContract("GnosisSafe", deployer);


  await deploy("BalancerPoolToken", {
    from: deployer,
    args: testingStakeHolders,
    log: true,
    waitConfirmations: 5,
  });


  const BalancerPoolToken = await ethers.getContract("BalancerPoolToken", deployer);

  await deploy("Voting", {
    from: deployer,
    args: [ BalancerPoolToken.address , GnosisSafe.address ],
    log: true,
    waitConfirmations: 5,
  });

  const Voting = await ethers.getContract("Voting", deployer);

  // Initialize Safe
  await GnosisSafe.setup(["0x9BB09321140d2Ed471867bE56b5D5936BAB93E85"], 1, "0x9BB09321140d2Ed471867bE56b5D5936BAB93E85", 0x30, Voting.address, BalancerPoolToken.address, 0, "0x9BB09321140d2Ed471867bE56b5D5936BAB93E85");

};
module.exports.tags = ["Voting", "GnosisSafe", "BalancerPoolToken"];
