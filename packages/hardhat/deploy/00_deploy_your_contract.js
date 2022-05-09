// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

// const sleep = (ms) =>
//   new Promise((r) =>
//     setTimeout(() => {
//       console.log(`waited for ${(ms / 1000).toFixed(3)} seconds`);
//       r();
//     }, ms)
//   );

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  await deploy("GnosisSafe", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract
  const GnosisSafe = await ethers.getContract("GnosisSafe", deployer);

  /*
  await deploy("GnosisSafeProxyFactory", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract
  const GnosisSafeProxyFactory = await ethers.getContract("GnosisSafeProxyFactory", deployer);

  //const {ProxyAddress} = await GnosisSafeProxyFactory.createProxy(GnosisSafe.address, 0x30);
*/
  
  /*await deploy("GnosisSafeProxyFactory", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract
  const GnosisSafeProxyFactory = await ethers.getContract("GnosisSafeProxyFactory", deployer);
*/
  //const proxy = await GnosisSafeProxyFactory.createProxy(GnosisSafe.address, "0x6164644f776e6572576974685468726573686f6c6428616464726573732c2075696e74323536292c203078394242303933323131343064324564343731383637624535366235443539333642414239334538352c2031");
  //console.log(proxy);

  await deploy("EnergyToken", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: ["0x9BB09321140d2Ed471867bE56b5D5936BAB93E85"],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract
  const EnergyToken = await ethers.getContract("EnergyToken", deployer);

  //console.log("ProxyAddress: "+ProxyAddress);

  await deploy("Voting", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [ EnergyToken.address , GnosisSafe.address ],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract
  const Voting = await ethers.getContract("Voting", deployer);

  await GnosisSafe.setup(["0x9BB09321140d2Ed471867bE56b5D5936BAB93E85"], 1, "0x9BB09321140d2Ed471867bE56b5D5936BAB93E85", 0x30, Voting.address, EnergyToken.address, 0, "0x9BB09321140d2Ed471867bE56b5D5936BAB93E85");

  /*  await YourContract.setPurpose("Hello");
  
    To take ownership of yourContract using the ownable library uncomment next line and add the 
    address you want to be the owner. 
    // await yourContract.transferOwnership(YOUR_ADDRESS_HERE);

    //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
  */

  /*
  //If you want to send value to an address from the deployer
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some ETH to a contract on deploy (make your constructor payable!)
  const yourContract = await deploy("YourContract", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const yourContract = await deploy("YourContract", [], {}, {
   LibraryName: **LibraryAddress**
  });
  */

  // Verify from the command line by running `yarn verify`

  // You can also Verify your contracts with Etherscan here...
  // You don't want to verify on localhost
  // try {
  //   if (chainId !== localChainId) {
  //     await run("verify:verify", {
  //       address: YourContract.address,
  //       contract: "contracts/YourContract.sol:YourContract",
  //       contractArguments: [],
  //     });
  //   }
  // } catch (error) {
  //   console.error(error);
  // }
};
module.exports.tags = ["Voting", "GnosisSafe", "EnergyToken"];
