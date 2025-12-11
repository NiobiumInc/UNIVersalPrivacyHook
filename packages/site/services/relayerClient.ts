// relayerClient.ts
// ---------------------------------------------------------------------
// Existing function (kept intact)
export async function sendOperandsToRelayer(relayerUrl: string, p: {
  intentId: string;
  poolId: string;
  user: string;
  tokenIn: string;
  tokenOut: string;
  bitWidth: number;
  operands: string[];   // base64-encoded bincode<FheUintXX>
}) {
  const resp = await fetch(`${relayerUrl}/relayer/intent`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(p),
  });
  if (!resp.ok) {
    const txt = await resp.text();
    throw new Error(`Relayer POST failed ${resp.status}: ${txt}`);
  }
  return resp.json();
}

// ---------------------------------------------------------------------
// === New latency demo helpers ===

// type for input payload (same structure)
export type InputProofReq = {
  intentId: `0x${string}`;
  poolId: `0x${string}`;
  user: `0x${string}`;
  tokenIn: `0x${string}`;
  tokenOut: `0x${string}`;
  bitWidth: number;          // e.g. 64
  operands: string[];        // base64-encoded bincode<FheUintXX>
};

// generic function that measures RTT
async function postTimed<T>(url: string, body: any): Promise<T & { _client_rtt_ms: number }> {
  const t0 = performance.now();
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  const json = await res.json();
  const t1 = performance.now();
  return { ...json, _client_rtt_ms: t1 - t0 };
}

// call Zama SDK endpoint
export async function sendToZama(req: InputProofReq) {
  return postTimed<any>('https://relayer.testnet.zama.cloud/v1/input-proof', req);
}

// call your own relayer endpoint
export async function sendToMine(req: InputProofReq) {
  const base = process.env.NEXT_PUBLIC_RELAYER_URL || 'http://localhost:8080';
  return postTimed<any>(`${base}/v1/input-proof`, req);
}

// helper to get ciphertexts from your HPU server
export async function hpuEncrypt(value: number | bigint, bitWidth = 64): Promise<string> {
  const base = process.env.NEXT_PUBLIC_HPU_URL || 'http://localhost:8087';
  const res = await fetch(`${base}/encrypt`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ bit_width: bitWidth, value: Number(value) }),
  });
  const json = await res.json();
  if (!json?.success) throw new Error(`HPU encrypt failed: ${json?.error}`);
  return json.result as string; // base64 ciphertext
}

