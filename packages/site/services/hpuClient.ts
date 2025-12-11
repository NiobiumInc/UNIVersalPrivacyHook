// ======================
// HPU Client Helpers
// ======================

// Base URL for your HPU server (Rust demo)
export const HPU_URL =
  process.env.NEXT_PUBLIC_HPU_URL || "http://localhost:8080";

// ---------- Minimal decrypt (testing your /decrypt path) ----------

export async function hpuDecryptMinimal(params: {
  ciphertextB64: string; // base64 of bincode<FheUintXX> OR mock-json base64 in demo_mode
  bitWidth: number;      // 8 | 16 | 32 | 64
  baseUrl?: string;      // override; defaults to HPU_URL
}) {
  const { ciphertextB64, bitWidth, baseUrl } = params;
  const url = `${baseUrl || HPU_URL}/decrypt`;

  const r = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      bit_width: bitWidth,
      operand: ciphertextB64,
    }),
  });

  if (!r.ok) {
    const t = await r.text().catch(() => "");
    throw new Error(`HPU /decrypt failed: ${r.status} ${t}`);
  }

  // Server returns ComputeResponse { success, result: base64(JSON or bytes), ... }
  const json = await r.json();
  if (!json.success || !json.result) {
    throw new Error(`HPU /decrypt error: ${json.error ?? "unknown"}`);
  }

  // In your current server, /decrypt wraps plaintext into a JSON object then base64-encodes it.
  // So decode base64 -> UTF-8 string -> JSON.
  const decodedStr = typeof atob !== "undefined"
    ? atob(json.result as string)
    : Buffer.from(json.result as string, "base64").toString("utf-8"); // SSR fallback

  const payload = JSON.parse(decodedStr); // { value, bit_width, encrypted:false, mock:true }
  return { plaintext: String(payload.value) };
}

// ---------- Vector compute (/compute_vec) ----------

export type HpuVecParams = {
  op: "add" | "subtract" | "xor"; // keep in sync with server
  bit_width: 8 | 16 | 32 | 64;
  operands: string[]; // base64 bincode<FheUintXX>
};

export type HpuVecResponse = {
  success: boolean;
  result?: string;              // base64 bincode<FheUintXX> (aggregate)
  count: number;
  error?: string | null;
  computation_time_ms?: number | null;
  _client_rtt_ms?: number | null;
};

export async function hpuComputeAggregate(
  params: HpuVecParams
): Promise<HpuVecResponse> {
  const t0 = typeof performance !== "undefined" ? performance.now() : Date.now();
  const r = await fetch(`${HPU_URL}/compute_vec`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(params),
  });
  const t1 = typeof performance !== "undefined" ? performance.now() : Date.now();

  if (!r.ok) {
    const t = await r.text().catch(() => "");
    throw new Error(`HPU /compute_vec failed: ${r.status} ${t}`);
  }
  const j = (await r.json()) as HpuVecResponse;
  j._client_rtt_ms = (t1 - t0) as number;
  return j;
}

// ---------- Single compute (/compute) for Option B flow ----------

export type HpuComputeRequest = {
  op: "resolve" | "sum";       // choose what your server implements
  bit_width: number;
  ciphertexts: string[];       // base64
  user_public_key: string;     // base64 (ephemeral pubkey)
  // optional auth / intent proof
  eip712_signature?: string;
  eip712_message?: any;
  contractAddresses?: string[];
  startTimeStamp?: string;
  durationDays?: string;
};

export type HpuComputeResponse = {
  success: boolean;
  resultCiphertextBase64?: string; // NOTE: different field name than vector API
  error?: string;
  timing_ms?: number;              // server timing
  _client_rtt_ms?: number;         // client RTT added here
};

export async function hpuHealth(): Promise<boolean> {
  try {
    const r = await fetch(`${HPU_URL}/health`);
    return r.ok;
  } catch {
    return false;
  }
}

export async function computeOnHPU(
  req: HpuComputeRequest
): Promise<HpuComputeResponse> {
  const t0 = Date.now();
  const r = await fetch(`${HPU_URL}/compute`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(req),
  });
  const t1 = Date.now();

  if (!r.ok) {
    const t = await r.text().catch(() => "");
    throw new Error(`HPU /compute failed: ${r.status} ${t}`);
  }
  const j = (await r.json()) as HpuComputeResponse;
  j._client_rtt_ms = t1 - t0;
  return j;
}


