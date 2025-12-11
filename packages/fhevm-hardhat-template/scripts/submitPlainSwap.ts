import { ethers } from "hardhat";

const POOL_SWAP_TEST = "0x9b6b46e2c869aa39918db7f52f5557fe577b6eee";
const HOOK_ADDRESS   = "0x0000000000000000000000000000000000000000";
const USDC = "0x792f8182d6737a977c68f606826C462C185Daa68";
const USDT = "0xde632641A6a1ff2251c3E28F6B83750016741984";

const FEE = 3000;
const TICK_SPACING = 60;
const MIN_SQRT_PRICE_PLUS_ONE  = 4295128740n;
const MAX_SQRT_PRICE_MINUS_ONE = 1461446703485210103287273052203988822378723970341n;

async function main() {
  const [signer] = await ethers.getSigners();
  console.log("Sender:", signer.address);

  const currency0 = USDC.toLowerCase() < USDT.toLowerCase() ? USDC : USDT;
  const currency1 = currency0 === USDC ? USDT : USDC;

  const poolKey = [
    currency0, currency1, FEE, TICK_SPACING, HOOK_ADDRESS,
  ] as const;

  const zeroForOne = currency0 === USDC; // USDC -> USDT
  const amountIn   = ethers.parseUnits("10", 6);

  const swapParams = [
    zeroForOne, amountIn,
    zeroForOne ? MIN_SQRT_PRICE_PLUS_ONE : MAX_SQRT_PRICE_MINUS_ONE,
  ] as const;

  const testSettings = [false, false] as const;

  const erc20Abi = ["function approve(address,uint256) external returns (bool)"];
  const token = new ethers.Contract(zeroForOne ? USDC : USDT, erc20Abi, signer);
  await (await token.approve(POOL_SWAP_TEST, ethers.parseUnits("100000", 6))).wait();

  const poolSwapTestAbi = [
    "function swap((address,address,uint24,int24,address),(bool,int256,uint160),(bool,bool),bytes) external"
  ];
  const swapTest = new ethers.Contract(POOL_SWAP_TEST, poolSwapTestAbi, signer);

  const hookData = "0x"; // <-- PLAIN: no encrypted payload
  console.log("Submitting PLAIN swap (no hookData)...");
  const tx = await swapTest.swap(poolKey, swapParams, testSettings, hookData, { gasLimit: 1_200_000 });
  console.log("tx:", tx.hash);
  const rcpt = await tx.wait();
  console.log("✅ confirmed in block", rcpt.blockNumber);
}

main().catch(e => { console.error(e); process.exit(1); });
