import { ethers } from "hardhat";

// --- from your setup ---
const POOL_MANAGER   = "0xE03A1074c86CFeDd5C142C4F04F1a1536e203543";
const POOL_SWAP_TEST = "0x9b6b46e2c869aa39918db7f52f5557fe577b6eee";
const HOOK_ADDRESS   = "0x9078D30062A5b50621A5635Ed75e1EA0449F0080";

// If you changed mocks in SetupPool.ts, replace these with the exact addresses you used there:
const USDC = "0x792f8182d6737a977c68f606826C462C185Daa68";
const USDT = "0xde632641A6a1ff2251c3E28F6B83750016741984";

// --- paste from testRelayer.mjs output ---
const HANDLES: string[] = [
  "0xf22515198a32e90772221180f0c20f0f06b312e033000000000000aa36a70500", // handle #1 (32 bytes hex)
  "0xcf57947e4096e1c833788940b45a07d0839d0181a6010000000000aa36a70500",  // handle #2
];
const INPUT_PROOF: string = 
"0x0201f22515198a32e90772221180f0c20f0f06b312e033000000000000aa36a70500cf57947e4096e1c833788940b45a07d0839d0181a6010000000000aa36a70500ae8347de904cab68233d75f8b3613117f1250cafc8dfc85181365ae16c5c514f7b0c415d82058a77a74a0c6efc0f62b470e19d62e90b1949ff654f336863b9101c00"; // bytes hex


// quick guards
for (const h of HANDLES) {
  if (!/^0x[0-9a-fA-F]{64}$/.test(h)) {
    throw new Error(`handle is not 32 bytes hex: ${h}`);
  }
}
if (!/^0x[0-9a-fA-F]*$/.test(INPUT_PROOF) || INPUT_PROOF.length % 2 !== 0) {
  throw new Error("INPUT_PROOF must be even-length 0x-hex");
}



// Match SetupPool.ts constants
const FEE = 3000;
const TICK_SPACING = 60;
const MIN_SQRT_PRICE_PLUS_ONE  = 4295128740n;
const MAX_SQRT_PRICE_MINUS_ONE = 1461446703485210103287273052203988822378723970341n;

async function main() {
  const [signer] = await ethers.getSigners();
  console.log("Sender:", signer.address);

  // Build the same poolKey used during setup
  const currency0 = USDC.toLowerCase() < USDT.toLowerCase() ? USDC : USDT;
  const currency1 = currency0 === USDC ? USDT : USDC;

  const poolKey = [
    currency0,
    currency1,
    FEE,
    TICK_SPACING,
    HOOK_ADDRESS,
  ] as const; 

  // Small swap; tokenIn must be approved & you must hold it
  const zeroForOne = currency0 === USDC;               // USDC -> USDT
  const amountIn = ethers.parseUnits("10", 6);       // 10 USDC

  const swapParams = [
    zeroForOne,
    amountIn,                        // positive => exact input
    zeroForOne ? MIN_SQRT_PRICE_PLUS_ONE : MAX_SQRT_PRICE_MINUS_ONE,
  ] as const;

  const testSettings = [
    false,
    false,
  ] as const;

  // Encode encrypted payload for hookData
  const hookData = ethers.AbiCoder.defaultAbiCoder().encode(
    ["bytes32[]","bytes"],
    [HANDLES, INPUT_PROOF]
  );

  // Minimal ABI for PoolSwapTest.swap used in SetupPool.ts
  const poolSwapTestAbi = [
    "function swap((address,address,uint24,int24,address),(bool,int256,uint160),(bool,bool),bytes) external"
  ];
  const swapTest = new ethers.Contract(POOL_SWAP_TEST, poolSwapTestAbi, signer);

  // Make sure the input token is approved to PoolSwapTest
  const erc20Abi = ["function approve(address,uint256) external returns (bool)"];
  if (zeroForOne) {
    const usdc = new ethers.Contract(USDC, erc20Abi, signer);
    await (await usdc.approve(POOL_SWAP_TEST, ethers.parseUnits("100000", 6))).wait();
  } else {
    const usdt = new ethers.Contract(USDT, erc20Abi, signer);
    await (await usdt.approve(POOL_SWAP_TEST, ethers.parseUnits("100000", 6))).wait();
  }

  console.log("Submitting encrypted swap with hookData (opaque bytes)...");
  const tx = await swapTest.swap(poolKey, swapParams, testSettings, hookData, { gasLimit: 1_500_000 });
  console.log("tx:", tx.hash);
  const rcpt = await tx.wait();
  console.log("✅ confirmed in block", rcpt.blockNumber);
}

main().catch((e) => { console.error(e); process.exit(1); });
