const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

const owner1 = 0x809F55D088872FFB148F86b5C21722CAa609Ac72;
const owner2 = 0xad635e085f2213b6025a660C36C6Ef78F5bf498a;


use(solidity);

describe("Voting App", function () {
  let gnosisSafe;
  let voting;
  let balancerPoolToken;

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  describe("GnosisSafe", function () {
    it("Should deploy GnosisSafe", async function () {
      const GnosisSafe = await ethers.getContractFactory("GnosisSafe");

      gnosisSafe = await GnosisSafe.deploy();
    });

      
    });
  });

  describe("BalancerPoolToken", function () {
    it("Should deploy BalancerPoolToken", async function () {
      const BalancerPoolToken = await ethers.getContractFactory("BalancerPoolToken");

      balancerPoolToken = await BalancerPoolToken.deploy(owner1, owner2);
    });
  });

  describe("Voting", function () {
    it("Should deploy Voting", async function () {
      const Voting = await ethers.getContractFactory("Voting");

      voting = await Voting.deploy(balancerPoolToken.address, gnosisSafe.address);
    });

    describe("submitProposal()", function () {
      it("Should submit a proposal to addSigner", async function () {
        const target = owner1;
        const threshold = 0;
        const actionType = 0;
        const proposalValue = 0;
        const proposal = "Add signer";

        //await voting.submitProposal(target, threshold, actionType, proposalValue, proposal);
        expect(await voting.submitProposal())
          to.emit(voting, 0, address(this))
            .withArgs(target, threshold, actionType, proposalValue, proposal);
      });

      it("should count votes", async function () {
        const proposalIndex = 0;
        const voteFor = 0;

        expect(await voting.vote())
          .to.emit(voting, 0, address(this), 1000*10**18)
            .withArgs(0, 0);
        });
    });
  });

});
