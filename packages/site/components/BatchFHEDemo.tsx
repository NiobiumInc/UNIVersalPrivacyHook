import React, { useState } from 'react';
import { useBatchFHE } from '@/hooks/usebatchFHE';
import { FhevmInstance } from '@/fhevm/fhevmTypes';

interface Props {
  fhevmInstance: FhevmInstance;
  userAddress: string;
}

export function BatchFHEDemo({ fhevmInstance, userAddress }: Props) {
  const { loading, metrics, error, runBatchDemo } = useBatchFHE();
  const [batchSize, setBatchSize] = useState(50);

  const handleRunDemo = async () => {
    try {
      await runBatchDemo(batchSize, fhevmInstance, userAddress);
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div style={{ padding: '20px', border: '1px solid #ccc', borderRadius: '8px' }}>
      <h2>🚀 Batch FHE Demo - CPU vs HPU</h2>

      <div style={{ marginBottom: '20px' }}>
        <label>
          Batch Size:
          <input
            type="number"
            value={batchSize}
            onChange={(e) => setBatchSize(Number(e.target.value))}
            disabled={loading}
            min="1"
            max="1000"
            style={{ marginLeft: '10px', width: '100px' }}
          />
        </label>
      </div>

      <button
        onClick={handleRunDemo}
        disabled={loading}
        style={{
          padding: '10px 20px',
          fontSize: '16px',
          backgroundColor: loading ? '#ccc' : '#4CAF50',
          color: 'white',
          border: 'none',
          borderRadius: '4px',
          cursor: loading ? 'not-allowed' : 'pointer',
        }}
      >
        {loading ? '⏳ Running...' : '▶ Run FHE Batch Demo'}
      </button>

      {error && (
        <div style={{ marginTop: '20px', padding: '10px', backgroundColor: '#ffcccc', borderRadius: '4px' }}>
          <strong>❌ Error:</strong> {error}
        </div>
      )}

      {metrics && (
        <div
          style={{
            marginTop: '20px',
            padding: '15px',
            backgroundColor: '#e8f5e9',
            borderRadius: '4px',
            fontFamily: 'monospace',
          }}
        >
          <h3>✅ Results</h3>
          <div>
            <strong>Items Processed:</strong> {batchSize}
          </div>
          <div>
            <strong>CPU Path (Decrypt + Sum):</strong> {metrics.cpuTimeMs}ms
          </div>
          <div>
            <strong>HPU Path (FHE Aggregation):</strong> {metrics.hpuTimeMs}ms
          </div>
          <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#2196F3', marginTop: '10px' }}>
            🚀 Speedup: {metrics.speedup}x
          </div>
          <div style={{ marginTop: '10px' }}>
            <strong>Verification:</strong> {metrics.verified ? '✓ PASSED' : '✗ FAILED'}
          </div>
          <div style={{ fontSize: '12px', marginTop: '10px', color: '#666' }}>
            CPU Sum: {metrics.cpuSum.substring(0, 30)}...
          </div>
        </div>
      )}
    </div>
  );
}