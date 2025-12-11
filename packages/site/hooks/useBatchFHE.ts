import { useState } from 'react';
import { FhevmInstance } from '@/fhevm/fhevmTypes';
import { CONTRACTS } from '@/config/contracts';



interface EncryptedIntent {
  amount: bigint;
  encAmount: string;
  proof: string;
}

interface ComparisonMetrics {
  cpuTimeMs: number;
  hpuTimeMs: number;
  speedup: number;
  cpuSum: string;
  verified: boolean;
}

export function useBatchFHE() {
  const [loading, setLoading] = useState(false);
  const [metrics, setMetrics] = useState<ComparisonMetrics | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Generate test amounts
  const generateAmounts = (count: number): bigint[] => {
    return Array.from({ length: count }, (_, i) => {
      // Mix of amounts: 50, 100, 150, 200, etc.
      return BigInt(((i % 10) + 1) * 50) * BigInt(1e6); // Add 6 decimals
    });
  };

  // Encrypt amounts locally
  const encryptAmounts = async (
    amounts: bigint[],
    fhevmInstance: FhevmInstance,
    userAddress: string
  ): Promise<EncryptedIntent[]> => {
    const encrypted: EncryptedIntent[] = [];

    for (const amount of amounts) {
      const input = fhevmInstance.createEncryptedInput(
        CONTRACTS.UniversalPrivacyHook,
        userAddress
      );

      input.add128(amount);
      const encryptedData = await input.encrypt();

      encrypted.push({
        amount,
        encAmount: encryptedData.handles[0] as string,
        proof: encryptedData.inputProof as string,
      });
    }

    return encrypted;
  };

  // Send to relayer for CPU vs HPU comparison
  const runComparison = async (encryptedIntents: EncryptedIntent[]) => {
    const response = await fetch(
      `${process.env.REACT_APP_RELAYER_URL || 'http://localhost:8080'}/v1/batch-compare-cpu-hpu`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ intents: encryptedIntents }),
      }
    );

    if (!response.ok) {
      throw new Error(`Relayer error: ${response.statusText}`);
    }

    const result = await response.json();
    return result;
  };

  // Main demo flow
  const runBatchDemo = async (
    count: number,
    fhevmInstance: FhevmInstance,
    userAddress: string
  ) => {
    setLoading(true);
    setError(null);

    try {
      console.log(`🚀 Starting batch FHE demo with ${count} items...`);

      // Step 1: Generate amounts
      console.log('📊 Generating amounts...');
      const amounts = generateAmounts(count);
      console.log(`✓ Generated: ${amounts.map((a) => a.toString()).join(', ')}`);

      // Step 2: Encrypt locally
      console.log('🔐 Encrypting locally...');
      const startEncrypt = performance.now();
      const encrypted = await encryptAmounts(amounts, fhevmInstance, userAddress);
      const encryptTime = performance.now() - startEncrypt;
      console.log(`✓ Encrypted in ${Math.round(encryptTime)}ms`);

      // Step 3: Send to relayer for comparison
      console.log('⚡ Running CPU vs HPU comparison on relayer...');
      const comparison = await runComparison(encrypted);

      console.log(`✓ CPU time: ${comparison.cpuPath.timeMs}ms`);
      console.log(`✓ HPU time: ${comparison.hpuPath.timeMs}ms`);
      console.log(`✓ Speedup: ${comparison.speedup}x`);

      // Step 4: Verify correctness
      const cpuSum = BigInt(comparison.cpuPath.sum);
      const expectedSum = amounts.reduce((acc, val) => acc + val, BigInt(0));
      const verified = cpuSum === expectedSum;

      console.log(`\n✅ Verification: ${verified ? 'PASSED' : 'FAILED'}`);
      console.log(`   Expected sum: ${expectedSum.toString()}`);
      console.log(`   CPU computed: ${cpuSum.toString()}`);

      const metricsData: ComparisonMetrics = {
        cpuTimeMs: comparison.cpuPath.timeMs,
        hpuTimeMs: comparison.hpuPath.timeMs,
        speedup: comparison.speedup,
        cpuSum: cpuSum.toString(),
        verified,
      };

      setMetrics(metricsData);
      return metricsData;
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Unknown error';
      console.error('❌ Error:', errorMsg);
      setError(errorMsg);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return {
    loading,
    metrics,
    error,
    runBatchDemo,
  };
}