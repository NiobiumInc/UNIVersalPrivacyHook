// packages/site/hooks/useUniversalPrivacyHook.ts
import { useCallback, useState } from "react";
import { ethers } from "ethers";
import { useMetaMaskEthersSigner } from "./metamask/useMetaMaskEthersSigner";

import { UniversalPrivacyHookABI } from "../abi/UniversalPrivacyHookABI";
import { MockERC20ABI } from "../abi/MockERC20ABI";
import { HybridFHERC20ABI } from "../abi/HybridFHERC20ABI";
import { CONTRACTS, getPoolKey } from "../config/contracts";

import { sendOperandsToRelayer } from '../services/relayerClient';
import { sendToMine, sendToZama } from "../services/relayerClient";


const RELAYER_URL = process.env.NEXT_PUBLIC_RELAYER_URL ?? 'http://localhost:8080';
const ZAMA_RELAYER_URL = process.env.NEXT_PUBLIC_ZAMA_RELAYER_URL ?? 'http://relayer.testnet.zama.cloud';
const GATEWAY_CHAIN_ID = Number(process.env.NEXT_PUBLIC_GATEWAY_CHAIN_ID ?? 55815);


if (typeof window !== 'undefined') {
  console.log('[ENV] RELAYER_URL =', RELAYER_URL);
}


// HPU client helpers
import {
  hpuDecryptMinimal,
  hpuComputeAggregate,
  computeOnHPU,
} from "../services/hpuClient";


const amountIn = 123;
const maxSlippage = 456;


/*
// basic helper to encrypt a number using HPU REST API
async function hpuEncrypt(value:number):  Promise<string> {
  const resp = await fetch('http://127.0.0.1:8087/encrypt',{

    method: 'POST',
    headers: {'content-type': 'application/json'},
    body: JSON.stringify({ bit_width: 64, value}),
  });

  if (!resp.ok) throw new Error('HPU ecnrypt failed: $(resp.status)');
  const json = await resp.json();
  return json.result;  // base64 cipphertext string
}
*/

/** ENV toggles (string "true"/"1" => enabled) */
const envTrue = (v?: string | null) =>
  v === "true" || v === "1" || v === "TRUE";

/** feature flags */
const USE_HPU_DECRYPT = envTrue(process.env.NEXT_PUBLIC_USE_HPU_DECRYPT);
const USE_HPU_COMPUTE = envTrue(process.env.NEXT_PUBLIC_USE_HPU_COMPUTE);

/** a public Sepolia RPC for read calls (no key needed) */
const PUBLIC_SEPOLIA = "https://ethereum-sepolia-rpc.publicnode.com";

/** Small utils */
const hexToBytes = (hex: string): Uint8Array => {
  const h = hex.startsWith("0x") ? hex.slice(2) : hex;
  if (h.length % 2 !== 0) throw new Error("hex length must be even");
  const out = new Uint8Array(h.length / 2);
  for (let i = 0; i < out.length; i++) {
    out[i] = parseInt(h.slice(i * 2, i * 2 + 2), 16);
  }
  return out;
};

const bytesToBase64 = (u8: Uint8Array) =>
  typeof window === "undefined"
    ? Buffer.from(u8).toString("base64")
    : btoa(String.fromCharCode(...u8));

/**
 * Try to resolve an on-chain "handle" (euint128 handle) into a raw ciphertext (bytes),
 * then return it as base64 so it can be fed to the HPU /compute_vec or /decrypt minimal.
 * NOTE: ABI method `getCiphertext(bytes32)` might not exist; we then fall back to raw call+decode.
 */
async function resolveHandleToCiphertextBase64(
  provider: ethers.Provider,
  handleHex: string
): Promise<string> {
  let h = handleHex.toLowerCase();
  if (!h.startsWith("0x")) h = "0x" + h;

  const hook = new ethers.Contract(
    CONTRACTS.UniversalPrivacyHook,
    UniversalPrivacyHookABI.abi,
    provider
  );

  // 1) Try ABI method (if present)
  try {
    const ciphertextHex: string = await (hook as any).getCiphertext(h);
    if (ciphertextHex && ciphertextHex !== "0x") {
      return bytesToBase64(hexToBytes(ciphertextHex));
    }
  } catch {
    // swallow and try low-level call
  }

  // 2) Low-level call using selector
  const selector = ethers.id("getCiphertext(bytes32)").slice(0, 10); // 0xabcdef01
  const data = selector + h.slice(2).padStart(64, "0");
  const res = await provider.call({
    to: CONTRACTS.UniversalPrivacyHook,
    data,
  });
  if (!res || res === "0x") {
    throw new Error("Could not resolve ciphertext for handle");
  }
  const [ciphertextHex] = ethers.AbiCoder.defaultAbiCoder().decode(
    ["bytes"],
    res
  ) as [string];
  return bytesToBase64(hexToBytes(ciphertextHex));
}

export const useUniversalPrivacyHook = () => {
  const { ethersSigner: signer, ethersBrowserProvider: provider } =
    useMetaMaskEthersSigner();

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  /** -------- Token flows (regular) -------- */

  const deposit = useCallback(
    async (currency: "USDC" | "USDT", amount: string) => {
      if (!signer) {
        setError("Please connect your wallet");
        return;
      }
      setLoading(true);
      setError(null);

      try {
        const poolKey = getPoolKey();
        const currencyAddress =
          currency === "USDC" ? CONTRACTS.MockUSDC : CONTRACTS.MockUSDT;

        // 6 decimals for both mock tokens
        const parsedAmount = ethers.parseUnits(amount, 6);

        const hook = new ethers.Contract(
          CONTRACTS.UniversalPrivacyHook,
          UniversalPrivacyHookABI.abi,
          signer
        );
        const token = new ethers.Contract(
          currencyAddress,
          MockERC20ABI.abi,
          signer
        );

        // Allowance & approve (2x headroom)
        const owner = await signer.getAddress();
        const allowance = await token.allowance(owner, CONTRACTS.UniversalPrivacyHook);
        const approvalAmount = parsedAmount * 2n;
        if (allowance < approvalAmount) {
          const approveTx = await token.approve(
            CONTRACTS.UniversalPrivacyHook,
            approvalAmount
          );
          await approveTx.wait();
        }

        const estimatedGas = await hook.deposit.estimateGas(
          poolKey,
          currencyAddress,
          parsedAmount
        );
        const gasLimit = (estimatedGas * 120n) / 100n;

        const tx = await hook.deposit(poolKey, currencyAddress, parsedAmount, {
          gasLimit,
        });
        await tx.wait();
        return tx.hash;
      } catch (e: any) {
        console.error("Deposit error:", e);
        setError(e?.message || "Deposit failed");
        throw e;
      } finally {
        setLoading(false);
      }
    },
    [signer]
  );

  const withdraw = useCallback(
    async (currency: "USDC" | "USDT", amount: string, recipient?: string) => {
      if (!signer) {
        setError("Please connect your wallet");
        return;
      }
      setLoading(true);
      setError(null);

      try {
        const poolKey = getPoolKey();
        const currencyAddress =
          currency === "USDC" ? CONTRACTS.MockUSDC : CONTRACTS.MockUSDT;
        const parsedAmount = ethers.parseUnits(amount, 6);
        const finalRecipient = recipient || (await signer.getAddress());

        const hook = new ethers.Contract(
          CONTRACTS.UniversalPrivacyHook,
          UniversalPrivacyHookABI.abi,
          signer
        );

        const estimatedGas = await hook.withdraw.estimateGas(
          poolKey,
          currencyAddress,
          parsedAmount,
          finalRecipient
        );
        const gasLimit = (estimatedGas * 120n) / 100n;

        const tx = await hook.withdraw(
          poolKey,
          currencyAddress,
          parsedAmount,
          finalRecipient,
          { gasLimit }
        );
        await tx.wait();
        return tx.hash;
      } catch (e: any) {
        console.error("Withdraw error:", e);
        setError(e?.message || "Withdraw failed");
        throw e;
      } finally {
        setLoading(false);
      }
    },
    [signer]
  );

  /** -------- Intent (encrypted swap) -------- */

  const submitIntent = useCallback(
    async (
      tokenIn: "USDC" | "USDT",
      tokenOut: "USDC" | "USDT",
      encryptedAmountHandleHex: string,
      inputProofHex: string,
      deadline?: number
    ) => {
      if (!signer) {
        setError("Please connect your wallet");
        return;
      }
      setLoading(true);
      setError(null);

      try {
        const poolKey = getPoolKey();
        const tokenInAddr =
          tokenIn === "USDC" ? CONTRACTS.MockUSDC : CONTRACTS.MockUSDT;
        const tokenOutAddr =
          tokenOut === "USDC" ? CONTRACTS.MockUSDC : CONTRACTS.MockUSDT;

        const finalDeadline =
          deadline ?? Math.floor(Date.now() / 1000) + 60 * 60; // +1h

        const hook = new ethers.Contract(
          CONTRACTS.UniversalPrivacyHook,
          UniversalPrivacyHookABI.abi,
          signer
        );

        // Estimation w/ fallback
        let gasLimit: bigint;
        try {
          const est = await hook.submitIntent.estimateGas(
            poolKey,
            tokenInAddr,
            tokenOutAddr,
            encryptedAmountHandleHex,
            inputProofHex,
            finalDeadline
          );
          gasLimit = (est * 120n) / 100n;
        } catch (estErr: any) {
          console.warn("Gas estimation failed:", estErr);
          gasLimit = 1_000_000n;
          if (estErr?.message?.includes("execution reverted")) {
            throw new Error(
              "Transaction would revert on-chain. Check balances/inputs."
            );
          }
        }

        console.log('Relayer config',{NEXT_PUBLIC_RELAYER_URL: process.env.NEXT_PUBLIC_RELAYER_URL});

        const tx = await hook.submitIntent(
          poolKey,
          tokenInAddr,
          tokenOutAddr,
          encryptedAmountHandleHex,
          inputProofHex,
          finalDeadline,
          { gasLimit }
        );
        const receipt = await tx.wait();

        // Try to pull IntentSubmitted event → intentId
        let intentId: string | null = null;
        let poolId: string | null = null;

        for (const log of receipt.logs ?? []) {
          try {
            const parsed = hook.interface.parseLog(log);
            if (parsed?.name === "IntentSubmitted") {
              intentId = parsed?.args?.intentId as string;
              break;
            }
          } catch {
            /* not our log */
          }
        }

        /*
        try {
          // 1) Prepare operands for both paths
          //    (use the same plaintexts you used to build inputs;
          //     here we encrypt them via your HPU to get base64<FheUint64>)
          const user = await signer.getAddress();
          //const encAmount_b64 = await hpuEncrypt(Number(amountIn));      // <-- your amount var
          //const encMaxSlip_b64 = await hpuEncrypt(Number(maxSlippage));  // <-- your slippage var


          console.log("Relayer SDK will handle encryption");

          

          const payload = {
            intentId: intentId as `0x${string}`,
            poolId:   (poolKey as string) as `0x${string}`,
            user:     (user as string) as `0x${string}`,
            tokenIn:  (tokenInAddr as string) as `0x${string}`,
            tokenOut: (tokenOutAddr as string) as `0x${string}`,
            bitWidth: 64,
            operands: [encAmount_b64, encMaxSlip_b64],
          };

          // 2) Fire both requests in parallel (SDK vs Your Relayer)
          const [sdkRes, mineRes] = await Promise.allSettled([
            sendToZama(payload),   // SDK path
            sendToMine(payload),   // Your relayer -> HPU path
          ]);

          // 3) Log timings
          if (sdkRes.status === 'fulfilled') {
            console.log('[SDK]  rtt_ms=', sdkRes.value._client_rtt_ms,
                        'server_ms=', sdkRes.value?.computation_time_ms);
          } else {
            console.warn('[SDK]  failed:', sdkRes.reason);
          }

          if (mineRes.status === 'fulfilled') {
            console.log('[HPU]  rtt_ms=', mineRes.value._client_rtt_ms,
                        'server_ms=', mineRes.value?.computation_time_ms);
          } else {
            console.warn('[HPU]  failed:', mineRes.reason);
          }
        } catch (postErr) {
          console.error('Failed to time SDK vs HPU:', postErr);
        }
        */
      
        const relayerResponse = (typeof window !== 'undefined' ? (window as any).__lastRelayerResponse : null);

        return { txHash: tx.hash, intentId,response: relayerResponse };
      } catch (e: any) {
        console.error("Submit intent error:", e);
        setError(e?.message || "Submit intent failed");
        throw e;
      } finally {
        setLoading(false);
      }
    },
    [signer]
  );

  const executeIntent = useCallback(
    async (intentId: string) => {
      if (!signer) {
        setError("Please connect your wallet");
        return;
      }
      setLoading(true);
      setError(null);

      try {
        const hook = new ethers.Contract(
          CONTRACTS.UniversalPrivacyHook,
          UniversalPrivacyHookABI.abi,
          signer
        );

        const est = await hook.executeIntent.estimateGas(intentId);
        const gasLimit = (est * 120n) / 100n;

        const tx = await hook.executeIntent(intentId, { gasLimit });
        await tx.wait();
        return tx.hash;
      } catch (e: any) {
        console.error("Execute intent error:", e);
        setError(e?.message || "Execute intent failed");
        throw e;
      } finally {
        setLoading(false);
      }
    },
    [signer]
  );

  /** -------- Balances (regular + encrypted) -------- */

  const getRegularBalance = useCallback(
    async (currency: "USDC" | "USDT", address?: string) => {
      if (!provider) return null;
      try {
        const tokenAddr =
          currency === "USDC" ? CONTRACTS.MockUSDC : CONTRACTS.MockUSDT;
        const who =
          address ??
          (await (async () => {
            if (!signer) return null;
            return await signer.getAddress();
          })());
        if (!who) return null;

        const token = new ethers.Contract(
          tokenAddr,
          MockERC20ABI.abi,
          provider
        );
        const bal = await token.balanceOf(who);
        return ethers.formatUnits(bal, 6);
      } catch (e) {
        console.error("getRegularBalance error:", e);
        return null;
      }
    },
    [provider, signer]
  );

  const getEncryptedBalance = useCallback(
    async (currency: "USDC" | "USDT", address?: string) => {
      if (!provider) return null;
      try {
        const encTokenAddr =
          currency === "USDC" ? CONTRACTS.EncryptedUSDC : CONTRACTS.EncryptedUSDT;
        const who =
          address ??
          (await (async () => {
            if (!signer) return null;
            return await signer.getAddress();
          })());
        if (!who) return null;

        const enc = new ethers.Contract(
          encTokenAddr,
          HybridFHERC20ABI.abi,
          provider
        );

        // IMPORTANT: this returns the encrypted handle (euint128), not plaintext.
        const encHandle = await enc.encBalances(who);
        return encHandle?.toString?.() ?? String(encHandle);
      } catch (e) {
        console.error("getEncryptedBalance error:", e);
        return null;
      }
    },
    [provider, signer]
  );



const decryptBalance = useCallback(
  async (
    encryptedHandle: string,
    tokenAddress: string,
    fhevmInstance: any,
    _optionalStorage?: any
  ) => {
    if (!signer || !provider || !fhevmInstance) {
      console.warn('[Decrypt] Missing deps:', {signer, provider, fhevmInstance});
      return null;
    }

    try {
      console.log('[Decrypt] Starting decryption...');
      
      // Normalize handle
      let handleHex = encryptedHandle;
      if (!handleHex.startsWith("0x")) handleHex = "0x" + handleHex;
      handleHex = handleHex.toLowerCase();

      // SDK path ONLY - no relayer calls
      console.log('Using SDK decrypt (client-side only)');
      
      const keypair = fhevmInstance.generateKeypair();
      const checksummedAddress = ethers.getAddress(tokenAddress);

      const startTimeStampStr = Math.floor(Date.now() / 1000).toString();
      const durationDaysStr = "10";
      const contractAddresses = [checksummedAddress];

      const eip712 = fhevmInstance.createEIP712(
        keypair.publicKey,
        contractAddresses,
        startTimeStampStr,
        durationDaysStr
      );

      const cleanTypes = {
        UserDecryptRequestVerification: eip712.types.UserDecryptRequestVerification
      };

      const signature = await signer.signTypedData(
        eip712.domain,
        cleanTypes,
        eip712.message
      );

      const cleanSignature = signature.startsWith("0x")
        ? signature.slice(2)
        : signature;

      const handlePairs = [
        { handle: handleHex, contractAddress: checksummedAddress },
      ];

      console.log('[Decrypt] Calling SDK userDecrypt...');
      const result = await fhevmInstance.userDecrypt(
        handlePairs,
        keypair.privateKey,
        keypair.publicKey,
        cleanSignature,
        contractAddresses,
        await signer.getAddress(),
        startTimeStampStr,
        durationDaysStr
      );

      console.log('[Decrypt] SDK returned:', result);

      let plain: string;
      if (typeof result === 'string') {
        plain = result;
      } else if (typeof result === 'number' || typeof result === 'bigint') {
        plain = result.toString();
      } else if (result && typeof result === 'object') {
        const maybe =
          (result as any).value ??
          (result as any).amount ??
          (result as any).plaintext ??
          (result as any)[checksummedAddress];
        plain = String(maybe ?? '');
      } else {
        plain = '';
      }

      console.log('[Decrypt] Returning plaintext:', plain);
      return plain;
    } catch (err) {
      console.error('[Decrypt] Error:', err);
      throw err;
    }
  },
  [signer, provider]
);


  /**
   * decryptBalance — called by UI like:
   *   decryptBalance(encHandle, CONTRACTS.EncryptedUSDC, fhevmInstance, storage?)
   * If USE_HPU_DECRYPT is enabled, we:
   *   - resolve handle -> base64 ciphertext
   *   - POST to HPU /decrypt minimal
   *   - return plaintext string
   * Otherwise, we use fhevmInstance.userDecrypt (original SDK path).
   
  
  const decryptBalance = useCallback(
    async (
      encryptedHandle: string,
      tokenAddress: string,
      fhevmInstance: any,
      _optionalStorage?: any // kept for backward-compat with your UI signature
    ) => {
      if (!signer || !provider || !fhevmInstance) {
        console.warn('[Decrypt] Missing deps:', {signer, provider, fhevmInstance});
        return null;

      }
 
      console.warn('[Decrypt] early exit guard', {
        signer: !!signer,
        provider: provider,
        fhevmInstance: !!fhevmInstance});


      // normalize handle
      let handleHex = encryptedHandle;
      if (!handleHex.startsWith("0x")) handleHex = "0x" + handleHex;
      handleHex = handleHex.toLowerCase();

      // HPU path
      if (USE_HPU_DECRYPT) {
        const readProvider = new ethers.JsonRpcProvider(PUBLIC_SEPOLIA);
        const ctB64 = await resolveHandleToCiphertextBase64(
          readProvider,
          handleHex
        );

        // server expects base64 bincode<FheUintXX> & bit_width
        const bitWidth = 64; // balances are u64 in this demo
        const res = await hpuDecryptMinimal({
          ciphertextB64: ctB64,
          bitWidth,
          baseUrl:
            process.env.NEXT_PUBLIC_RELAYER_URL || "http://localhost:8080",
        });

        // HPU returns { plaintext: "12345" }
        return res.plaintext;
      }

      // SDK fallback (kept intact)

      console.log('Taking SDK decrypt path');
      const keypair = fhevmInstance.generateKeypair(); // { publicKey, privateKey }
      const checksummedAddress = ethers.getAddress(tokenAddress);

      const startTimeStampStr = Math.floor(Date.now() / 1000).toString();
      const durationDaysStr = "10";
      const contractAddresses = [checksummedAddress]

      const eip712 = fhevmInstance.createEIP712(
        keypair.publicKey,
        contractAddresses,
        startTimeStampStr,
        durationDaysStr
      );

      const cleanTypes = {
        UserDecryptRequestVerification: eip712.types.UserDecryptRequestVerification
      };
      
      
      const cleanMessage = {
        ...eip712.message,
        contractsChainId: BigInt(11155111),
        startTimestamp: BigInt(startTimeStamp),
        durationDays: BigInt(durationDays),
        contractAddresses: [] as string[],
      }
      

      const signature = await signer.signTypedData(
        eip712.domain,
        cleanTypes,
        eip712.message
      );

      const cleanSignature = signature.startsWith("0x")
        ? signature.slice(2)
        : signature;

      const handlePairs = [
        { handle: handleHex, contractAddress: checksummedAddress },
      ];

      const result = await fhevmInstance.userDecrypt(
        handlePairs,
        keypair.privateKey,
        keypair.publicKey,
        cleanSignature,
        contractAddresses,
        await signer.getAddress(),
        startTimeStampStr,
        durationDaysStr
      );

      console.log('SDK decrypt returned',result);


      let plain: string;
      if (typeof result == 'string'){
        plain = result;
      } else if (typeof result == 'number' || typeof result == 'bigint'){
        plain = result.toString();
      } else if (result && typeof result == 'object'){
        const maybe =
          (result as any).value ??
          (result as any).amount ??
          (result as any).plaintext ??
          (result as any)[checksummedAddress];
        plain = String(maybe ?? '');
      } else{
        plain = '';
      }

      // SDK generally returns a stringified plaintext amount
      console.warn('[Decrypt on plaintext');
      return plain;
    },
    [signer, provider]
  );
*/

  /** -------- Listen / Inspect intents on-chain -------- */

  const listenForIntentDecrypted = useCallback(
    (callback: (intentId: string, amount: string) => void) => {
      if (!provider) return;
      const hook = new ethers.Contract(
        CONTRACTS.UniversalPrivacyHook,
        UniversalPrivacyHookABI.abi,
        provider
      );
      const filter = hook.filters.IntentDecrypted();
      const listener = (_intentId: string, decryptedAmount: bigint) => {
        callback(_intentId, ethers.formatUnits(decryptedAmount, 6));
      };
      hook.on(filter, listener);
      return () => hook.off(filter, listener);
    },
    [provider]
  );

  const checkIntentStatus = useCallback(
    async (intentId: string) => {
      if (!provider) return null;
      try {
        const hook = new ethers.Contract(
          CONTRACTS.UniversalPrivacyHook,
          UniversalPrivacyHookABI.abi,
          provider
        );
        const intent = await hook.intents(intentId);
        if (intent && intent.decryptedAmount && intent.decryptedAmount > 0n) {
          return {
            isDecrypted: Boolean(intent.decrypted ?? intent[6]),
            amount: ethers.formatUnits(intent.decryptedAmount, 6),
            isExecuted: Boolean(intent.processed ?? intent[5]),
          };
        }
        return { isDecrypted: false, amount: null, isExecuted: false };
      } catch (e) {
        console.error("checkIntentStatus error:", e);
        return null;
      }
    },
    [provider]
  );

  const fetchUserIntents = useCallback(async (userAddress?: string) => {
    try {
      const readProvider = new ethers.JsonRpcProvider(PUBLIC_SEPOLIA);
      const hook = new ethers.Contract(
        CONTRACTS.UniversalPrivacyHook,
        UniversalPrivacyHookABI.abi,
        readProvider
      );

      let who = userAddress;
      if (!who && signer) who = await signer.getAddress();
      if (!who) return [];

      // Search last ~300 blocks (~1 hour)
      const currentBlock = await readProvider.getBlockNumber();
      const fromBlock = Math.max(0, currentBlock - 300);

      const filter = hook.filters.IntentSubmitted(
        null,
        null,
        null,
        who,
        null
      );
      const events = await hook.queryFilter(filter, fromBlock, currentBlock);

      const intents = await Promise.all(
        events.map(async (ev) => {
          try {
            const parsed = hook.interface.parseLog({
              topics: ev.topics as string[],
              data: ev.data,
            });
            const intentId = parsed?.args?.intentId as string | undefined;

            // read batches(bytes32) via raw call to also show status
            let batchId: string | null = null;
            let batchStatus = "unknown";

            if (intentId) {
              const intentsSel = ethers
                .id("intents(bytes32)")
                .slice(0, 10);
              const iData = await readProvider.call({
                to: CONTRACTS.UniversalPrivacyHook,
                data: intentsSel + intentId.slice(2).padStart(64, "0"),
              });

              const decoded = ethers.AbiCoder.defaultAbiCoder().decode(
                [
                  "bytes32",
                  "address",
                  "address",
                  "address",
                  "uint64",
                  "bool",
                  "tuple(address,address,uint24,int24,address)",
                  "bytes32",
                ],
                iData
              );

              batchId = decoded[7];

              if (batchId && batchId !== ethers.ZeroHash) {
                const batchesSel = ethers
                  .id("batches(bytes32)")
                  .slice(0, 10);
                const bData = await readProvider.call({
                  to: CONTRACTS.UniversalPrivacyHook,
                  data: batchesSel + batchId.slice(2).padStart(64, "0"),
                });
                const bDec = ethers.AbiCoder.defaultAbiCoder().decode(
                  ["uint256", "uint256", "bool", "bool"],
                  bData
                );
                const finalized = Boolean(bDec[2]);
                const settled = Boolean(bDec[3]);
                batchStatus = settled
                  ? "settled"
                  : finalized
                  ? "finalized"
                  : "processing";
              }
            }

            return {
              id: ev.transactionHash,
              transactionHash: ev.transactionHash,
              blockNumber: ev.blockNumber,
              user: who!,
              tokenIn: parsed?.args?.tokenIn ?? "",
              tokenOut: parsed?.args?.tokenOut ?? "",
              batchId,
              batchStatus,
              deadline: 0,
              decryptedAmount: null,
              executed: false,
              timestamp: 0,
            };
          } catch {
            return null;
          }
        })
      );

      return intents.filter(Boolean) as NonNullable<typeof intents[number]>[];
    } catch (e) {
      console.error("fetchUserIntents error:", e);
      return [];
    }
  }, [signer]);

  /** -------- Optional: HPU aggregate demo (UI button) --------
   * Example helper you can call from the UI to show HPU /compute_vec timing.
   * You pass in N handles and we return server timings (and an optional plaintext
   * if you choose to decrypt the result afterward with the SDK path).
   */
  const aggregateEncryptedBalance = useCallback(
    async (handles: string[], tokenAddress: string, fhevmInstance?: any) => {
      if (!handles?.length) return null;

      // Resolve each handle -> base64 ciphertext
      const readProvider = new ethers.JsonRpcProvider(PUBLIC_SEPOLIA);
      const ctB64s: string[] = [];
      for (const h of handles) {
        ctB64s.push(await resolveHandleToCiphertextBase64(readProvider, h));
      }

      if (USE_HPU_COMPUTE) {
        const res = await hpuComputeAggregate({
          op: "add",
          bit_width: 64,
          operands: ctB64s,
        });
        if (!res.success || !res.result) {
          throw new Error(res.error || "HPU compute_vec failed");
        }

        // Optionally decrypt the aggregate here (either SDK userDecrypt-from-raw
        // if supported in your SDK build, or the HPU minimal decrypt again).
        let sumPlain: string | null = null;
        if (fhevmInstance) {
          // If your SDK can decrypt from raw ciphertext, use that:
          // sumPlain = fhevmInstance.decryptFromBase64(res.result, <privateKey>)
          // Otherwise, use HPU minimal decrypt to display:
          const dec = await hpuDecryptMinimal({
            ciphertextB64: res.result,
            bitWidth: 64,
            baseUrl:
              process.env.NEXT_PUBLIC_RELAYER_URL || "http://localhost:8080",
          });
          sumPlain = dec.plaintext;
        }

        return {
          sumCiphertextB64: res.result,
          sumPlain,
          server_ms: res.computation_time_ms ?? null,
          rtt_ms: (res as any)._client_rtt_ms ?? null,
          n: res.count,
        };
      }

      // Baseline (no HPU): caller can decrypt each ct and sum in UI for comparison
      return {
        sumCiphertextB64: null,
        sumPlain: null,
        server_ms: null,
        rtt_ms: null,
        n: ctB64s.length,
      };
    },
    []
  );

  /** -------- Mint (faucet) -------- */

  const mintTokens = useCallback(
    async (currency: "USDC" | "USDT", amount: string) => {
      if (!signer) {
        setError("Please connect your wallet");
        return;
      }
      setLoading(true);
      setError(null);
      try {
        const tokenAddr =
          currency === "USDC" ? CONTRACTS.MockUSDC : CONTRACTS.MockUSDT;
        const token = new ethers.Contract(tokenAddr, MockERC20ABI.abi, signer);
        const parsed = ethers.parseUnits(amount, 6);
        const tx = await token.mint(await signer.getAddress(), parsed);
        await tx.wait();
        return tx.hash;
      } catch (e: any) {
        console.error("Mint error:", e);
        setError(e?.message || "Mint failed");
        throw e;
      } finally {
        setLoading(false);
      }
    },
    [signer]

  );

  // ============ BATCH TRANSACTION METHODS ============
  
  const prepareBatchTransactions = useCallback(
    async (
      transactions: any[],
      currency: "USDC" | "USDT",
      useEncryption: boolean = false
    ): Promise<any[]> => {
      console.log(`📦 Preparing batch of ${transactions.length} transactions...`);
      return transactions.map(tx => ({
        ...tx,
        timestamp: Date.now(),
        status: 'pending' as const,
      }));
    },
    []
  );

  const submitBatchTransactions = useCallback(
    async (
      transactions: any[],
      currency: "USDC" | "USDT"
    ): Promise<any> => {
      if (!signer) {
        throw new Error("Please connect wallet");
      }

      if (!transactions.length) {
        throw new Error("No transactions to submit");
      }

      setLoading(true);
      const batchStartTime = performance.now();
      const networkStartTime = Date.now();

      try {
        const poolKey = getPoolKey();
        const currencyAddress =
          currency === "USDC" ? CONTRACTS.MockUSDC : CONTRACTS.MockUSDT;

        // Calculate total for approval
        const totalAmount = transactions.reduce((sum: any, tx: any) => {
          return sum + ethers.parseUnits(tx.amount, 6);
        }, 0n);

        const hook = new ethers.Contract(
          CONTRACTS.UniversalPrivacyHook,
          UniversalPrivacyHookABI.abi,
          signer
        );

        const token = new ethers.Contract(
          currencyAddress,
          MockERC20ABI.abi,
          signer
        );

        const owner = await signer.getAddress();
        const allowance = await token.allowance(owner, CONTRACTS.UniversalPrivacyHook);

        if (allowance < totalAmount) {
          const approveTx = await token.approve(
            CONTRACTS.UniversalPrivacyHook,
            totalAmount * 2n
          );
          await approveTx.wait();
        }

        console.log(`📦 Submitting ${transactions.length} transactions...`);

        for (let i = 0; i < transactions.length; i++) {
          const tx = transactions[i];
          console.log(`  [${i + 1}/${transactions.length}] Sending...`);

          const txResponse = await hook.deposit(
            poolKey,
            currencyAddress,
            ethers.parseUnits(tx.amount, 6)
          );

          await txResponse.wait();
        }

        const networkEndTime = Date.now();
        const batchEndTime = performance.now();

        const totalTimeMs = batchEndTime - batchStartTime;
        const networkLatencyMs = networkEndTime - networkStartTime;
        const tps = transactions.length / (totalTimeMs / 1000);

        console.log(`✅ Batch complete!`);
        console.log(`  TPS: ${tps.toFixed(2)} tx/s`);

        return {
          batchId: `batch-${Date.now()}`,
          transactionHash: `0x${Date.now()}`,
          timestamp: Date.now(),
          totalAmount: ethers.formatUnits(totalAmount, 6),
          transactionCount: transactions.length,
          networkLatencyMs,
          totalTimeMs,
          tps,
          recipients: transactions.map((t: any) => t.recipient),
          amounts: transactions.map((t: any) => t.amount),
          status: 'confirmed',
        };

      } catch (e: any) {
        console.error("Batch error:", e);
        throw e;
      } finally {
        setLoading(false);
      }
    },
    [signer]
  );

  const decryptBatchResults = useCallback(
    async (batchResult: any): Promise<any | null> => {
      return null;
    },
    []
  );

  const calculateEffectiveTPS = useCallback(
    (batchResult: any, handleComputationMs?: number): number => {
      let totalMs = batchResult.totalTimeMs;
      if (handleComputationMs) {
        totalMs += handleComputationMs;
      }
      return batchResult.transactionCount / (totalMs / 1000);
    },
    []
  );

  const [batchTransactions, setBatchTransactions] = useState<any[]>([]);

  const getBatchHistory = useCallback((): any[] => {
    return batchTransactions;
  }, [batchTransactions]);

  const clearBatchHistory = useCallback((): void => {
    setBatchTransactions([]);
  }, []);

  const submitBatchTransactionsWithRelayer = useCallback(
  async (
    transactions: any[],
    currency: "USDC" | "USDT"
  ): Promise<any> => {
    if (!signer) {
      throw new Error("Please connect wallet");
    }

    if (!transactions.length) {
      throw new Error("No transactions to submit");
    }

    const batchStartTime = performance.now();
    const networkStartTime = Date.now();

    try {
      setLoading(true);
      console.log(`🚀 Submitting REAL batch of ${transactions.length} transactions via relayer...`);

      // ============ STEP 1: Prepare batch payload ============
      const batchPayload = {
        transactions: transactions.map(tx => ({
          recipient: tx.recipient,
          amount: tx.amount,
          currency: currency,
        })),
        timestamp: Date.now(),
        sender: await signer.getAddress(),
        chainId: GATEWAY_CHAIN_ID,
      };

      console.log(`📋 Batch payload:`, batchPayload);

      // ============ STEP 2: Process through relayer ============
      console.log(`📤 Sending batch to relayer for processing...`);
      const relayerStartTime = performance.now();

      const relayerResults = await Promise.allSettled(
        transactions.map(async (tx, index) => {
          try {
            console.log(`  [${index + 1}/${transactions.length}] Processing: ${tx.recipient} (${tx.amount})`);

            // Call your relayer's input-proof endpoint
            // This gets handles and signatures from Zama
            const relayerResponse = await fetch('http://localhost:8080/v1/input-proof', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                contractAddress: CONTRACTS.UniversalPrivacyHook,
                userAddress: await signer.getAddress(),
                ciphertextWithInputVerification: tx.encryptedAmount || '0x00',
                contractChainId: GATEWAY_CHAIN_ID,
                extraData: '0x',
              }),
            });

            if (!relayerResponse.ok) {
              throw new Error(`Relayer returned ${relayerResponse.status}`);
            }

            const data = await relayerResponse.json();
            
            return {
              txIndex: index,
              recipient: tx.recipient,
              amount: tx.amount,
              handle: data.response?.handles?.[0],
              signatures: data.response?.signatures || [],
              performance: data._performance || {},
            };
          } catch (err) {
            console.error(`  ❌ [${index + 1}] Failed:`, err);
            throw err;
          }
        })
      );

      const relayerTime = performance.now() - relayerStartTime;
      console.log(`✅ Relayer processed batch in ${relayerTime.toFixed(2)}ms`);

      // ============ STEP 3: Check results ============
      const failedCount = relayerResults.filter(r => r.status === 'rejected').length;
      if (failedCount > 0) {
        console.warn(`⚠️  ${failedCount} transactions failed in relayer`);
      }

      const successResults = relayerResults
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value);

      console.log(`✅ ${successResults.length}/${transactions.length} succeeded`);

      // ============ STEP 4: Collect performance metrics ============
      let cpuTotalMs = 0;
      let hpuTotalMs = 0;
      let hpuAvailableCount = 0;

      successResults.forEach((result: any) => {
        if (result.performance) {
          cpuTotalMs += result.performance.cpu_compute_ms || 0;
          if (result.performance.hpu_available) {
            hpuTotalMs += result.performance.hpu_compute_ms || 0;
            hpuAvailableCount += 1;
          }
        }
      });

      // ============ STEP 5: Submit to blockchain ============
      if (successResults.length === 0) {
        throw new Error("No transactions succeeded in relayer");
      }

      console.log(`📋 Submitting ${successResults.length} transactions to blockchain...`);
      const blockchainStartTime = performance.now();

      const poolKey = getPoolKey();
      const currencyAddress =
        currency === "USDC" ? CONTRACTS.MockUSDC : CONTRACTS.MockUSDT;

      const hook = new ethers.Contract(
        CONTRACTS.UniversalPrivacyHook,
        UniversalPrivacyHookABI.abi,
        signer
      );

      const token = new ethers.Contract(
        currencyAddress,
        MockERC20ABI.abi,
        signer
      );

      // Approve if needed
      const totalAmount = transactions.reduce((sum, tx) => {
        return sum + ethers.parseUnits(tx.amount, 6);
      }, 0n);

      const owner = await signer.getAddress();
      const allowance = await token.allowance(owner, CONTRACTS.UniversalPrivacyHook);

      if (allowance < totalAmount) {
        console.log(`📝 Approving token spend...`);
        const approveTx = await token.approve(
          CONTRACTS.UniversalPrivacyHook,
          totalAmount * 2n
        );
        await approveTx.wait();
      }

      // Submit transactions to blockchain
      const blockchainTxHashes: string[] = [];
      
      for (let i = 0; i < successResults.length; i++) {
        const result = successResults[i];
        try {
          console.log(`  [${i + 1}/${successResults.length}] Submitting to blockchain...`);

          const txResponse = await hook.deposit(
            poolKey,
            currencyAddress,
            ethers.parseUnits(result.amount, 6)
          );

          await txResponse.wait();
          blockchainTxHashes.push(txResponse.hash);

          console.log(`  ✅ Confirmed: ${txResponse.hash}`);
        } catch (err) {
          console.error(`  ❌ Blockchain submission failed:`, err);
        }
      }

      const blockchainTime = performance.now() - blockchainStartTime;
      console.log(`✅ Blockchain transactions submitted in ${blockchainTime.toFixed(2)}ms`);

      // ============ STEP 6: Calculate metrics ============
      const networkEndTime = Date.now();
      const batchEndTime = performance.now();

      const totalTimeMs = batchEndTime - batchStartTime;
      const networkLatencyMs = networkEndTime - networkStartTime;
      const tps = transactions.length / (totalTimeMs / 1000);

      const result = {
        batchId: `batch-${Date.now()}`,
        timestamp: Date.now(),
        totalAmount: transactions.reduce((sum, tx) => sum + Number(tx.amount), 0),
        transactionCount: transactions.length,
        successCount: successResults.length,
        failureCount: failedCount,
        
        // REAL METRICS
        relayerProcessingMs: relayerTime,
        blockchainSubmissionMs: blockchainTime,
        totalTimeMs,
        networkLatencyMs,
        tps,
        
        // HPU Performance Comparison (if available)
        cpuComputeMs: cpuTotalMs,
        hpuComputeMs: hpuTotalMs,
        hpuAvailable: hpuAvailableCount > 0,
        hpuSpeedup: hpuTotalMs > 0 ? (cpuTotalMs / hpuTotalMs).toFixed(2) : 'N/A',
        
        // Results
        recipients: successResults.map(r => r.recipient),
        amounts: successResults.map(r => r.amount),
        blockchainTxHashes,
        status: 'confirmed',
      };

      console.log(`✅ Batch complete!`);
      console.log(`  Transactions: ${result.successCount}/${result.transactionCount}`);
      console.log(`  Relayer time: ${result.relayerProcessingMs.toFixed(2)}ms`);
      console.log(`  Blockchain time: ${result.blockchainSubmissionMs.toFixed(2)}ms`);
      console.log(`  Total time: ${result.totalTimeMs.toFixed(2)}ms`);
      console.log(`  TPS: ${result.tps.toFixed(2)} tx/s`);
      
      if (result.hpuAvailable) {
        console.log(`  🚀 HPU speedup: ${result.hpuSpeedup}x faster than CPU`);
      }

      return result;

    } catch (e: any) {
      console.error("Batch error:", e);
      throw e;
    } finally {
      setLoading(false);
    }
  },
  [signer]
);



  return {
    // core flows
    deposit,
    withdraw,
    submitIntent,
    executeIntent,

    // balances
    getRegularBalance,
    getEncryptedBalance,
    decryptBalance,

    // intents
    listenForIntentDecrypted,
    checkIntentStatus,
    fetchUserIntents,

    // faucet & demos
    mintTokens,
    aggregateEncryptedBalance,

    // NEW BATCH METHODS:
    prepareBatchTransactions,
    submitBatchTransactions,
    decryptBatchResults,
    calculateEffectiveTPS,
    getBatchHistory,
    clearBatchHistory,
    batchTransactions,
    submitBatchTransactionsWithRelayer,


    // ui state
    loading,
    error,
  };
};
