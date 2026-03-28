const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // 1. Deploy StakedIdentity (The Governance Token)
  const StakedIdentity = await hre.ethers.getContractFactory("StakedIdentity");
  const token = await StakedIdentity.deploy("VetoToken", "VETO");
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log("StakedIdentity deployed to:", tokenAddress);

  // 2. Deploy VetoVault
  // Threshold set to 100,000 tokens (10% of total supply)
  const threshold = hre.ethers.parseEther("100000");
  const VetoVault = await hre.ethers.getContractFactory("VetoVault");
  const vault = await VetoVault.deploy(tokenAddress, threshold);
  await vault.waitForDeployment();
  const vaultAddress = await vault.getAddress();
  console.log("VetoVault deployed to:", vaultAddress);

  // 3. Deploy MockDAO
  const MockDAO = await hre.ethers.getContractFactory("MockDAO");
  const dao = await MockDAO.deploy(vaultAddress);
  await dao.waitForDeployment();
  const daoAddress = await dao.getAddress();
  console.log("MockDAO deployed to:", daoAddress);

  // 4. Linkage Phase: Establish the trust loop
  console.log("Linking contracts...");

  // Set the Governor (MockDAO) in the VetoVault
  // Note: VetoVault.sol uses Ownable, so we transfer ownership or set a specific authorized caller.
  // In our VetoVault.sol, queueProposal is public but should ideally be restricted.
  // For this MVP, we ensure the DAO is the one calling it.
  
  // Transfer ownership of the Vault to the DAO so only the DAO can manage it (e.g. update thresholds)
  const transferTx = await vault.transferOwnership(daoAddress);
  await transferTx.wait();
  console.log("VetoVault ownership transferred to MockDAO");

  // Verify linkage by checking DAO's vault address
  const linkedVault = await dao.vault();
  console.log("MockDAO is linked to Vault at:", linkedVault);

  console.log("Deployment and linkage complete.");
  
  // Summary for frontend/integration
  console.log("---------------------------");
  console.log("TOKEN_ADDRESS=" + tokenAddress);
  console.log("VAULT_ADDRESS=" + vaultAddress);
  console.log("DAO_ADDRESS=" + daoAddress);
  console.log("---------------------------");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });