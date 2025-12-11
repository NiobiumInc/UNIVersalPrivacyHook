import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Zap, Gauge, CheckCircle, AlertCircle } from 'lucide-react';

interface PerformanceData {
  demo_summary?: {
    headline: string;
    fastest_method: string;
    speedup_vs_zama: string;
    verification_status: string;
  };
  cpu_compute_ms?: number;
  hpu_compute_ms?: number | null;
  hpu_available?: boolean;
  zama_total_ms?: number;
  total_request_ms?: number;
  cpu_vs_zama_speedup?: string | number;
  hpu_vs_zama_speedup?: string | number | null;
  cpu_vs_hpu_speedup?: string | number | null;
  hpu_advantage_ms?: number;
  cpu_matches_zama?: boolean;
  hpu_matches_zama?: boolean;
}

interface PerformanceComparisonProps {
  performanceData?: PerformanceData | null;
  isLoading?: boolean;
}

export function PerformanceComparison({
  performanceData,
  isLoading = false,
}: PerformanceComparisonProps) {
  const [displayData, setDisplayData] = useState<PerformanceData | null>(null);

  useEffect(() => {
    if (performanceData) {
      setDisplayData(performanceData);
    }
  }, [performanceData]);

  if (!displayData && !isLoading) {
    return null;
  }

  const summary = displayData?.demo_summary;
  const cpuTime = displayData?.cpu_compute_ms;
  const hpuTime = displayData?.hpu_compute_ms;
  const zamaTime = displayData?.zama_total_ms;
  const hpuAvailable = displayData?.hpu_available;
  const cpuVsZama = displayData?.cpu_vs_zama_speedup;
  const hpuVsZama = displayData?.hpu_vs_zama_speedup;
  const cpuVsHpu = displayData?.cpu_vs_hpu_speedup;
  const hpuAdvantage = displayData?.hpu_advantage_ms;
  const cpuMatchesZama = displayData?.cpu_matches_zama;
  const hpuMatchesZama = displayData?.hpu_matches_zama;

  return (
    <Card className="bg-gradient-to-br from-blue-50 to-indigo-50 border-2 border-blue-200 shadow-lg">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="text-2xl font-bold text-gray-900">
              ⚡ Privacy Proof Performance
            </CardTitle>
            <CardDescription className="text-base mt-1">
              Real-time handle computation comparison
            </CardDescription>
          </div>
          {isLoading && (
            <div className="animate-spin">
              <Gauge className="h-6 w-6 text-blue-600" />
            </div>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-6">
        {/* Main Headline */}
        {summary && (
          <div className="bg-white rounded-lg p-4 border-2 border-blue-300">
            <p className="text-lg font-mono font-bold text-gray-800">
              {summary.headline}
            </p>
            <p className="text-sm text-blue-600 font-semibold mt-2">
              {summary.speedup_vs_zama}
            </p>
          </div>
        )}

        {/* Timing Breakdown */}
        {(cpuTime || hpuTime || zamaTime) && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* CPU */}
            <div className="bg-white rounded-lg p-4 border border-gray-300">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
                <span className="text-sm font-semibold text-gray-700">CPU</span>
              </div>
              <p className="text-3xl font-bold text-gray-900">
                {cpuTime !== undefined ? `${cpuTime}ms` : '—'}
              </p>
              <p className="text-xs text-gray-500 mt-2">
                {cpuVsZama ? `${cpuVsZama}x faster than Zama` : '—'}
              </p>
              {cpuMatchesZama && (
                <div className="flex items-center gap-1 mt-2 text-xs text-green-600">
                  <CheckCircle className="h-3 w-3" />
                  <span>Verified</span>
                </div>
              )}
            </div>

            {/* HPU */}
            {hpuAvailable && (
              <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-lg p-4 border-2 border-green-400 ring-2 ring-green-200">
                <div className="flex items-center gap-2 mb-2">
                  <Zap className="h-4 w-4 text-green-600" />
                  <span className="text-sm font-bold text-green-700">HPU ⭐</span>
                </div>
                <p className="text-3xl font-bold text-green-900">
                  {hpuTime !== undefined && hpuTime !== null ? `${hpuTime.toFixed(1)}ms` : '—'}
                </p>
                <p className="text-xs text-green-600 font-semibold mt-2">
                  {hpuVsZama ? `${hpuVsZama}x faster than Zama` : '—'}
                </p>
                {hpuMatchesZama && (
                  <div className="flex items-center gap-1 mt-2 text-xs text-green-700 font-semibold">
                    <CheckCircle className="h-3 w-3" />
                    <span>Verified</span>
                  </div>
                )}
              </div>
            )}

            {/* Zama */}
            <div className="bg-white rounded-lg p-4 border border-gray-300">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-3 h-3 rounded-full bg-gray-400"></div>
                <span className="text-sm font-semibold text-gray-700">Zama Cloud</span>
              </div>
              <p className="text-3xl font-bold text-gray-900">
                {zamaTime !== undefined ? `${zamaTime}ms` : '—'}
              </p>
              <p className="text-xs text-gray-500 mt-2">Baseline (network + compute)</p>
            </div>
          </div>
        )}

        {/* Speedup Comparison */}
        {hpuAvailable && hpuTime && cpuVsHpu && (
          <div className="bg-green-50 border-l-4 border-green-500 p-4 rounded">
            <div className="flex items-start gap-3">
              <Zap className="h-5 w-5 text-green-600 mt-0.5" />
              <div>
                <p className="font-bold text-green-900">HPU vs CPU Speedup</p>
                <p className="text-sm text-green-700 mt-1">
                  HPU is <span className="font-bold text-lg">{cpuVsHpu}x faster</span> than CPU
                  {hpuAdvantage !== undefined && hpuAdvantage > 0 && (
                    <span> (saves {hpuAdvantage.toFixed(1)}ms)</span>
                  )}
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Verification Status */}
        {summary && (
          <div
            className={`flex items-start gap-3 p-4 rounded ${
              summary.verification_status.includes('✅')
                ? 'bg-green-50 border-l-4 border-green-500'
                : 'bg-yellow-50 border-l-4 border-yellow-500'
            }`}
          >
            {summary.verification_status.includes('✅') ? (
              <CheckCircle className="h-5 w-5 text-green-600 mt-0.5" />
            ) : (
              <AlertCircle className="h-5 w-5 text-yellow-600 mt-0.5" />
            )}
            <div>
              <p
                className={`font-semibold ${
                  summary.verification_status.includes('✅')
                    ? 'text-green-900'
                    : 'text-yellow-900'
                }`}
              >
                {summary.verification_status}
              </p>
              <p className="text-xs text-gray-600 mt-1">
                CPU and HPU computations match Zama's result
              </p>
            </div>
          </div>
        )}

        {/* Loading State */}
        {isLoading && (
          <div className="flex flex-col items-center justify-center py-8 gap-2">
            <div className="animate-pulse flex gap-2">
              <div className="h-2 w-2 bg-blue-600 rounded-full animate-bounce"></div>
              <div className="h-2 w-2 bg-blue-600 rounded-full animate-bounce delay-100"></div>
              <div className="h-2 w-2 bg-blue-600 rounded-full animate-bounce delay-200"></div>
            </div>
            <p className="text-sm text-gray-600">Computing handles...</p>
          </div>
        )}

        {/* Add privacy status display */}

        <div className="bg-blue-50 border-l-4 border-blue-500 p-4 rounded mt-4">
          <h4 className="font-bold text-blue-900 mb-2">🔒 Privacy Status</h4>
          
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="font-semibold text-gray-700">CPU Path</p>
              <p className="text-gray-600">
                Data decrypted during aggregation
              </p>
              <p className="text-xs text-orange-600 mt-1">
                ⚠️ Privacy risk: Plaintext in memory
              </p>
            </div>
            
            <div>
              <p className="font-semibold text-gray-700">HPU Path</p>
              <p className="text-gray-600">
                Data stays encrypted throughout
              </p>
              <p className="text-xs text-green-600 mt-1">
                ✅ Complete privacy preservation
              </p>
            </div>
          </div>
        </div>

        <div className="bg-green-50 border-l-4 border-green-500 p-4 rounded mt-4">
          <p className="text-green-900 font-bold">
            🌟 HPU Advantage: {speedup}x faster WHILE preserving end-to-end privacy
          </p>
          <p className="text-sm text-green-700 mt-2">
            This is why HPU matters for sensitive applications like DeFi, healthcare, 
            and any system where data privacy is critical.
          </p>
        </div>



      </CardContent>
    </Card>
  );
}