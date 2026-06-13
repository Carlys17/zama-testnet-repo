import { ethers, network } from "hardhat";
import * as fs from "fs";
import * as path from "path";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Network:", network.name);

  const deployed: Record<string, string> = {};

  // 1. EncryptedERC20
  const Erc20 = await ethers.getContractFactory("EncryptedERC20");
  const erc20 = await Erc20.deploy("ConfToken", "CTK", 6, 1_000_000n);
  await erc20.waitForDeployment();
  deployed.EncryptedERC20 = await erc20.getAddress();
  console.log("EncryptedERC20  ->", deployed.EncryptedERC20);

  // 2. PrivateVoting
  const Vote = await ethers.getContractFactory("PrivateVoting");
  const vote = await Vote.deploy();
  await vote.waitForDeployment();
  deployed.PrivateVoting = await vote.getAddress();
  console.log("PrivateVoting   ->", deployed.PrivateVoting);

  // 3. BlindAuction (60 min bidding, 30 min reveal)
  const Auc = await ethers.getContractFactory("BlindAuction");
  const auc = await Auc.deploy(60, 30, deployer.address);
  await auc.waitForDeployment();
  deployed.BlindAuction = await auc.getAddress();
  console.log("BlindAuction    ->", deployed.BlindAuction);

  // 4. ConfidentialLottery (0.01 ETH per ticket)
  const Lot = await ethers.getContractFactory("ConfidentialLottery");
  const lot = await Lot.deploy(ethers.parseEther("0.01"));
  await lot.waitForDeployment();
  deployed.ConfidentialLottery = await lot.getAddress();
  console.log("ConfidentialLottery ->", deployed.ConfidentialLottery);

  // Save
  const out = path.join(__dirname, "..", "deployments", `${network.name}-all.json`);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, JSON.stringify(deployed, null, 2));
  console.log("\nSaved to", out);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
