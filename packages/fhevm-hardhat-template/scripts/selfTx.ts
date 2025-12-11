import { ethers } from "hardhat";

async function main() {
  const [signer] = await ethers.getSigners();
  console.log("Sending self-tx from:", signer.address);

  const tx = await signer.sendTransaction({
    to: signer.address,
    value: 0n, // send 0 ETH
  });

  console.log("Tx hash:", tx.hash);
  console.log("Waiting for confirmation...");
  await tx.wait(1);

  console.log("✅ Self-tx confirmed!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
