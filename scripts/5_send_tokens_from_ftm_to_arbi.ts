import { BigNumber } from "ethers";
import { ethers } from "hardhat";

const bnToNumber = (bn: BigNumber) =>
  bn.div(BigNumber.from("10").pow(BigNumber.from("16"))).toNumber() / 100;

async function main() {
  const [owner] = await ethers.getSigners();
  const ethBalance = await owner.provider?.getBalance(owner.address);
  console.log("ETH balance", bnToNumber(ethBalance!));

  const amount = ethers.utils.parseEther("45");

  const Omnitoken = await ethers.getContractFactory("Omnitoken");
  const omnitoken = Omnitoken.attach("0x7e2ffB16333a4bB35cBB6e8cFFb74FFDcb13A245");

  const expectedFeesRaw = (await omnitoken.estimateFees(owner.address, amount, 10010))[0];
  const expectedFees = bnToNumber(expectedFeesRaw);
  console.log("Expected fees:", expectedFees);

  console.log("Sending")
  await omnitoken.crossChainTransfer(
    owner.address,
    amount,
    10010,
    { value: ethers.utils.parseEther("1.25") }
  );

  console.log("Sent from FANTOM to ARBITRUM:");

  const balance = await omnitoken.balanceOf(owner.address);
  console.log("User balance", bnToNumber(balance));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
