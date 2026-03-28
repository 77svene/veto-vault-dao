const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("VetoVault Governance Flow", function () {
  let vault, token, dao, deployer, staker, attacker;
  const VETO_THRESHOLD = ethers.parseEther("100");
  const STAKE_AMOUNT = ethers.parseEther("200");
  const CHALLENGE_WINDOW = 2 * 24 * 60 * 60; // 2 days
  const MIN_STAKE_DURATION = 180 * 24 * 60 * 60; // 180 days

  beforeEach(async function () {
    [deployer, staker, attacker] = await ethers.getSigners();

    // 1. Deploy StakedIdentity (Token)
    const Token = await ethers.getContractFactory("StakedIdentity");
    token = await Token.deploy("Governance Token", "GTK");

    // 2. Deploy VetoVault
    const Vault = await ethers.getContractFactory("VetoVault");
    vault = await Vault.deploy(await token.getAddress(), VETO_THRESHOLD);

    // 3. Deploy MockDAO
    const DAO = await ethers.getContractFactory("MockDAO");
    dao = await DAO.deploy(await vault.getAddress());

    // Setup staker with tokens and long-term age
    await token.transfer(staker.address, STAKE_AMOUNT);
    
    // Move time forward to simulate long-term staking
    // Note: VetoVault uses userStakeTime mapping which is set on registerStake()
    await vault.connect(staker).registerStake();
    await time.increase(MIN_STAKE_DURATION + 100);
  });

  it("Should prevent execution during the challenge window", async function () {
    const target = attacker.address;
    const value = ethers.parseEther("10");
    const data = "0x";
    const proposalId = 1;

    // DAO passes proposal
    await dao.passProposal(proposalId, target, value, data);

    // Attempt immediate execution should fail
    await expect(vault.execute(proposalId))
      .to.be.revertedWith("Challenge window open");
  });

  it("Should allow execution after window passes if no veto", async function () {
    const proposalId = 2;
    await dao.passProposal(proposalId, deployer.address, 0, "0x");

    // Wait for window to expire
    await time.increase(CHALLENGE_WINDOW + 1);

    await expect(vault.execute(proposalId)).to.emit(vault, "Executed");
    const prop = await vault.proposals(proposalId);
    expect(prop.executed).to.be.true;
  });

  it("Should block execution if veto threshold is reached", async function () {
    const proposalId = 3;
    await dao.passProposal(proposalId, attacker.address, ethers.parseEther("100"), "0x");

    // Staker casts veto
    // Staker has 200 tokens, threshold is 100
    await vault.connect(staker).castVeto(proposalId);

    const prop = await vault.proposals(proposalId);
    expect(prop.vetoPower).to.equal(STAKE_AMOUNT);
    expect(prop.vetoed).to.be.true;

    // Wait for window to expire
    await time.increase(CHALLENGE_WINDOW + 1);

    // Execution should fail because it is vetoed
    await expect(vault.execute(proposalId))
      .to.be.revertedWith("Proposal vetoed");
  });

  it("Should reject vetoes from accounts with young stakes", async function () {
    const proposalId = 4;
    await dao.passProposal(proposalId, attacker.address, 0, "0x");

    // Attacker gets tokens and registers now
    await token.transfer(attacker.address, STAKE_AMOUNT);
    await vault.connect(attacker).registerStake();

    // Veto should fail because stake is too young
    await expect(vault.connect(attacker).castVeto(proposalId))
      .to.be.revertedWith("Stake too young");
  });
});