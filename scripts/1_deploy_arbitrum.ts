import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import hre from "hardhat";

const bnToNumber = (bn: BigNumber) =>
  bn.div(BigNumber.from("10").pow(BigNumber.from("16"))).toNumber() / 100;

async function main() {
  const [owner] = await ethers.getSigners();
  const ethBalance = await owner.provider?.getBalance(owner.address);
  console.log("ETH balance", bnToNumber(ethBalance!));

  // deploy contract to ARBITRUM Testnet
  const lzEndpoint = "0x4D747149A57923Beb89f22E6B7B97f7D8c087A00";
  const Omnitoken = await ethers.getContractFactory("Omnitoken");
  const omnitoken = await Omnitoken.deploy(lzEndpoint);
  await omnitoken.deployed();
  console.log("Omnitoken deployed to:", omnitoken.address);

  // immediately verify contract
  await hre.run("verify:verify", {
    address: omnitoken.address,
    constructorArguments: [lzEndpoint],
  });

  // check OMNI user balance
  const balance = await omnitoken.balanceOf(owner.address);
  console.log("User balance", bnToNumber(balance));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
