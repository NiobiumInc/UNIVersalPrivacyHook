import { useState, useCallback } from 'react';

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

interface PerformanceHistory extends PerformanceData {
  timestamp: number;
  id: string;
}

export function usePerformanceTracking() {
  const [currentPerformance, setCurrentPerformance] = useState<PerformanceData | null>(null);
  const [performanceHistory, setPerformanceHistory] = useState<PerformanceHistory[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const recordPerformance = useCallback((data: PerformanceData) => {
    setCurrentPerformance(data);
    
    // Add to history
    const historyEntry: PerformanceHistory = {
      ...data,
      timestamp: Date.now(),
      id: `perf-${Date.now()}-${Math.random()}`,
    };
    
    setPerformanceHistory((prev) => [historyEntry, ...prev].slice(0, 50)); // Keep last 50
  }, []);

  const clearPerformance = useCallback(() => {
    setCurrentPerformance(null);
  }, []);

  const clearHistory = useCallback(() => {
    setPerformanceHistory([]);
  }, []);

  // Extract performance data from relayer response
  const extractPerformanceFromResponse = useCallback((response: any): PerformanceData | null => {
    if (!response || !response._performance) {
      return null;
    }
    return response._performance;
  }, []);

  return {
    currentPerformance,
    performanceHistory,
    isLoading,
    setIsLoading,
    recordPerformance,
    clearPerformance,
    clearHistory,
    extractPerformanceFromResponse,
  };
}