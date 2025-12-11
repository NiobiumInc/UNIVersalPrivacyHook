// site/src/debug/preflight.ts
// Minimal checks to isolate "Failed to check contract code" causes.

import { ethers } from "ethers";
import { Relayer } from "@zama-fhe/relayer-sdk/bundle";
import { CONTRACTS } from "@/config/contracts";

const EXPECTED_CHAIN_HEX = "0xAA36A7"; // Sepolia
const RELAYER_URL =
  // If your app has a config value for this, use it here instead:
  (process.env.NEXT_PUBLIC_RELAYER_URL as string) ||
  // SDK default is fine for Sepolia; leave undefined to use SDK's network preset
  "";

export async function runPreflight() {
  const out: Record<string, any> = {};

  // 1) Wallet/chain sanity
  const chainHex = await (window as any).ethereum?.request?.({
    method: "eth_chainId",
  });
  out.walletChainId = chainHex;
  out.walletOnSepolia = chainHex === EXPECTED_CHAIN_HEX;

  // 2) Hook address the UI is actually using
  out.hookFromContracts = CONTRACTS.UniversalPrivacyHook;

  // 3) Confirm bytecode exists via *your* RPC, not relayer
  const provider = new ethers.BrowserProvider((window as any).ethereum);
  const code = await provider.send("eth_getCode", [
    CONTRACTS.UniversalPrivacyHook,
    "latest",
  ]);
  out.hookHasCode = code !== "0x";
  out.codePrefix = code.slice(0, 12);

  // 4) Optional: EIP-1967 impl slot (proxy check)
  const IMPL_SLOT =
    "0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC";
  const proxyWord = await provider.send("eth_getStorageAt", [
    CONTRACTS.UniversalPrivacyHook,
    IMPL_SLOT,
    "latest",
  ]);
  out.isProxy = proxyWord !== "0x" + "0".repeat(64);

  // 5) Relayer health (if you have a URL configured)
  if (RELAYER_URL) {
    try {
      const res = await fetch(`${RELAYER_URL}/health`, { cache: "no-store" });
      out.relayerHealthStatus = res.status;
      out.relayerHealthBody = await res.text();
    } catch (e: any) {
      out.relayerHealthError = String(e);
    }
  } else {
    out.relayerHealthStatus = "(using SDK default)";
  }

  // 6) Minimal SDK ping by constructing the relayer client
  try {
    const relayer =
      RELAYER_URL && RELAYER_URL.length
        ? new Relayer({ url: RELAYER_URL, network: 11155111 })
        : new Relayer({ network: 11155111 }); // let SDK pick Sepolia default
    // Some SDKs expose a health method; if not, we at least confirm construction succeeded.
    out.sdkConstructed = true;
    // If a .health() exists in your SDK version, uncomment:
    // out.sdkHealth = await relayer.health();
  } catch (e: any) {
    out.sdkConstructed = false;
    out.sdkError = String(e);
  }

  console.table(out);
  return out;
}
