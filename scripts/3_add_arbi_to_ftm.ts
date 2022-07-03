import { BigNumber } from "ethers";
import { ethers } from "hardhat";

const bnToNumber = (bn: BigNumber) =>
  bn.div(BigNumber.from("10").pow(BigNumber.from("16"))).toNumber() / 100;

async function main() {
  const [owner] = await ethers.getSigners();
  const ethBalance = await owner.provider?.getBalance(owner.address);
  console.log("ETH balance", bnToNumber(ethBalance!));

  const OMNITOKEN_ARBITRUM_ADDRESS = "0x701301aE25c130144c975Ce84Dd0B6C363f9C44f";
  const Omnitoken = await ethers.getContractFactory("Omnitoken");
  const omnitoken = Omnitoken.attach("0xd3Cb8618C03269D5A01296D0f5A8003AF38B110B");
  await omnitoken.setOmnitokenAddressOnOtherChain(10010, OMNITOKEN_ARBITRUM_ADDRESS);
  console.log("SET");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
