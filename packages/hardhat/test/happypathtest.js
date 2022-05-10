const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

describe("Voting Dapp, Happy Path Simulation:", function () {
  let balancerPoolToken;
  let voting;
  let gnosisSafe;

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  describe("GnosisSafe", function () {
    it("Should deploy GnosisSafe", async function () {
      const [owner, address1, address2] = await ethers.getSigners();

      const GnosisSafe = await ethers.getContractFactory("GnosisSafe");

      gnosisSafe = await GnosisSafe.deploy();
    });
  });

  describe("BalancerPoolToken", function () {
    it("Should deploy BalancerPoolToken", async function () {
      const [owner, address1, address2] = await ethers.getSigners();
      const BalancerPoolToken = await ethers.getContractFactory("BalancerPoolToken");

      balancerPoolToken = await BalancerPoolToken.deploy(owner.address, address1.address);
    });
  });

  describe("Voting", function () {
    it("Should deploy Voting", async function () {
      const Voting = await ethers.getContractFactory("Voting");

      voting = await Voting.deploy(balancerPoolToken.address, gnosisSafe.address);
    });
  });

  describe("GnosisSafe", function () {
    
    describe("setup()", function () {
      it("Should setup safe", async function () {
        const [owner, address1, address2] = await ethers.getSigners();

        await gnosisSafe.setup([owner.address], 1, owner.address, 0x30, voting.address, balancerPoolToken.address, 0, owner.address);
        expect(await gnosisSafe.getOwners())
          .to.have.members([owner.address]);     
      });
      });
  });

  describe("Voting", function () {
    it("Should submitProposal for adding signer to safe", async function () {
      const [owner, address1, address2] = await ethers.getSigners();
      expect(await voting.submitProposal(address1.address, 1, 0, 0, ""))
        .to.emit(voting, "newProposal")
        .withArgs(0);
      
    });

    it("Should vote for proposal", async function () {
      const [owner, address1, address2] = await ethers.getSigners();

      expect(await voting.vote(0,0))
        .to.emit(voting, "voted")
        .withArgs(0,owner.address, ethers.utils.parseUnits("1000", 18),0);
      
    });

    it("Should account for votes", async function () {
      
      expect(await voting.getVotesForProposalByIndex(0))
        .to.equal(ethers.utils.parseUnits("1000", 18));
      
    });

    it("Should add signer immediately once vote passed", async function () {
      const [owner, address1, address2] = await ethers.getSigners();

      expect(await gnosisSafe.getOwners())
        .to.have.members([owner.address, address1.address]);
      
    });

    it("Should submitProposal for removing signer from safe", async function () {
      const [owner, address1, address2] = await ethers.getSigners();
      expect(await voting.submitProposal(address1.address, 1, 1, 0, ""))
        .to.emit(voting, "newProposal")
        .withArgs(1);
      
    });

    it("Should vote for proposal to remove signer", async function () {
      const [owner, address1, address2] = await ethers.getSigners();

      expect(await voting.vote(1,0))
        .to.emit(voting, "voted")
        .withArgs(1,owner.address, ethers.utils.parseUnits("1000", 18),0);
      
    });

    it("Should remove signer immediately once vote passed", async function () {
      const [owner, address1, address2] = await ethers.getSigners();

      expect(await gnosisSafe.getOwners())
        .to.have.members([owner.address]);
      
    });
  });
    
  
});

