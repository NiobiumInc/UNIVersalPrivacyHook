// BatchTransactionManager.tsx - CORRECTED WITH EXPORT

"use client";

import { useState } from 'react';
import { ethers } from 'ethers';
import toast from 'react-hot-toast';
import { Button } from './ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Input } from './ui/input';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import {
  Zap,
  Plus,
  Trash2,
  Send,
  TrendingUp,
  Clock,
  AlertCircle,
  CheckCircle,
  RefreshCw,
} from 'lucide-react';

interface BatchTxInput {
  id: string;
  recipient: string;
  amount: string;
}

export function BatchTransactionManager({ hook, isConnected, signer }: {
  hook: any;
  isConnected: boolean;
  signer: any;
}) {
  const [batchTransactions, setBatchTransactions] = useState<BatchTxInput[]>([]);
  const [batchCurrency, setBatchCurrency] = useState<'USDC' | 'USDT'>('USDC');
  const [batchAmount, setBatchAmount] = useState('10');
  const [numTransactions, setNumTransactions] = useState('5');
  const [useEncryption, setUseEncryption] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const [batchHistory, setBatchHistory] = useState<any[]>([]);

  const generateDemoBatch = async () => {
    const count = parseInt(numTransactions) || 1;
    const amount = batchAmount;

    if (count <= 0 || count > 100) {
      toast.error('Please enter 1-100 transactions');
      return;
    }

    if (!amount || parseFloat(amount) <= 0) {
      toast.error('Invalid amount per transaction');
      return;
    }

    console.log(`📦 Generating demo batch of ${count} transactions...`);

    const transactions: BatchTxInput[] = Array.from({ length: count }, (_, i) => ({
      id: `tx-${i}`,
      recipient: ethers.getAddress(
        '0x' + Array(40).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join('')
      ),
      amount,
    }));

    setBatchTransactions(transactions);
    toast.success(`Generated ${count} transactions`);
  };

    // UPDATED handleSubmitBatch for Real Relayer Batching
    // Replace your current handleSubmitBatch with this code

    const handleSubmitBatch = async () => {
    if (!isConnected) {
        toast.error('Please connect wallet first');
        return;
    }

    if (!batchTransactions.length) {
        toast.error('No transactions to submit');
        return;
    }

    try {
        setIsSubmitting(true);
        console.log('\n🚀 Submitting REAL batch via relayer...');

        // Use real relayer batching if available, fall back to fake
        const result = hook.submitBatchTransactionsWithRelayer
        ? await hook.submitBatchTransactionsWithRelayer(
            batchTransactions.map(tx => ({
                recipient: tx.recipient,
                amount: tx.amount,
            })),
            batchCurrency
            )
        : await hook.submitBatchTransactions(
            batchTransactions.map(tx => ({
                recipient: tx.recipient,
                amount: tx.amount,
            })),
            batchCurrency
            );

        console.log('✅ Batch submitted:', result);

        setBatchHistory(prev => [...prev, result]);
        setShowResults(true);

        // Show more detailed metrics when using real relayer
        const useRealRelayer = !!hook.submitBatchTransactionsWithRelayer;

        toast.success(
        <div>
            <div>✅ Batch confirmed!</div>
            <div className="text-sm mt-2">
            {result.successCount || result.transactionCount} txs in {result.totalTimeMs.toFixed(0)}ms
            </div>
            {useRealRelayer && result.relayerProcessingMs && (
            <>
                <div className="text-sm text-gray-600 mt-1">
                Relayer: {result.relayerProcessingMs.toFixed(0)}ms
                </div>
                <div className="text-sm text-gray-600">
                Blockchain: {result.blockchainSubmissionMs.toFixed(0)}ms
                </div>
            </>
            )}
            {result.hpuAvailable && (
            <div className="text-sm text-green-600 font-bold mt-1">
                🚀 HPU {result.hpuSpeedup}x faster than CPU
            </div>
            )}
            <div className="text-sm font-mono text-blue-600 mt-1">
            ⚡ {result.tps.toFixed(2)} TPS
            </div>
        </div>
        );

        setBatchTransactions([]);
        setNumTransactions('5');
    } catch (e: any) {
        console.error('Batch error:', e);
        toast.error(e.message || 'Batch submission failed');
    } finally {
        setIsSubmitting(false);
    }
    };


  const removeTransaction = (id: string) => {
    setBatchTransactions(prev => prev.filter(tx => tx.id !== id));
  };

  const totalBatchAmount = batchTransactions.reduce((sum, tx) => {
    return sum + parseFloat(tx.amount || '0');
  }, 0);

  return (
    <div className="space-y-6">
      {/* BATCH INPUT SECTION */}
      <Card className="bg-white/90 backdrop-blur-sm border-2 border-blue-200">
        <CardHeader className="bg-gradient-to-r from-blue-50 to-cyan-50">
          <div className="flex items-center gap-2">
            <Zap className="h-6 w-6 text-blue-600" />
            <div>
              <CardTitle className="text-2xl">Batch Transactions</CardTitle>
              <CardDescription>
                Send N transactions with only 1 wallet confirmation
              </CardDescription>
            </div>
          </div>
        </CardHeader>

        <CardContent className="p-6 space-y-6">
          {/* Currency Selection */}
          <div className="grid grid-cols-2 gap-4">
            {(['USDC', 'USDT'] as const).map((token) => (
              <Button
                key={token}
                onClick={() => setBatchCurrency(token)}
                variant={batchCurrency === token ? "default" : "outline"}
                className="h-12"
              >
                {token}
              </Button>
            ))}
          </div>

          {/* Demo Batch Generator */}
          <div className="bg-gradient-to-br from-blue-50 to-cyan-50 p-6 rounded-lg border border-blue-200">
            <h3 className="font-semibold text-lg mb-4">Quick Demo Setup</h3>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Number of Transactions</label>
                <Input
                  type="number"
                  value={numTransactions}
                  onChange={(e) => setNumTransactions(e.target.value)}
                  placeholder="5"
                  min="1"
                  max="100"
                  className="text-lg font-mono"
                />
                <p className="text-xs text-gray-600">1-100 transactions per batch</p>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">Amount per Transaction</label>
                <Input
                  type="number"
                  value={batchAmount}
                  onChange={(e) => setBatchAmount(e.target.value)}
                  placeholder="10"
                  step="0.1"
                  className="text-lg font-mono"
                />
                <p className="text-xs text-gray-600">{batchCurrency}</p>
              </div>

              <div className="flex items-end">
                <Button
                  onClick={generateDemoBatch}
                  variant="outline"
                  className="w-full h-12"
                  disabled={isSubmitting}
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Generate Batch
                </Button>
              </div>
            </div>

            {/* Encryption option */}
            <div className="flex items-center gap-2 p-3 bg-white rounded border">
              <input
                type="checkbox"
                id="useEncryption"
                checked={useEncryption}
                onChange={(e) => setUseEncryption(e.target.checked)}
                className="w-4 h-4"
              />
              <label htmlFor="useEncryption" className="text-sm font-medium cursor-pointer flex-1">
                🔐 Encrypt amounts on HPU before submission
              </label>
              <span className="text-xs text-gray-500">Optional</span>
            </div>
          </div>

          {/* Batch Summary */}
          {batchTransactions.length > 0 && (
            <div className="bg-gradient-to-br from-green-50 to-emerald-50 p-6 rounded-lg border border-green-200">
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <p className="text-sm text-gray-600">Transactions</p>
                  <p className="text-2xl font-bold text-green-600">{batchTransactions.length}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Amount per Tx</p>
                  <p className="text-lg font-mono text-green-600">{batchAmount} {batchCurrency}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Total Amount</p>
                  <p className="text-lg font-mono text-green-600">{totalBatchAmount.toFixed(2)} {batchCurrency}</p>
                </div>
              </div>
            </div>
          )}

          {/* Transaction List */}
          {batchTransactions.length > 0 && (
            <div className="space-y-2">
              <h4 className="font-semibold">Batch Transactions ({batchTransactions.length})</h4>
              <div className="max-h-48 overflow-y-auto space-y-2 bg-gray-50 p-4 rounded">
                {batchTransactions.map((tx, idx) => (
                  <div
                    key={tx.id}
                    className="flex items-center justify-between bg-white p-3 rounded border border-gray-200 text-sm"
                  >
                    <div className="flex-1">
                      <span className="font-mono text-xs text-gray-500">#{idx + 1}</span>
                      <p className="font-mono text-xs text-blue-600 truncate">
                        {tx.recipient.slice(0, 10)}...{tx.recipient.slice(-8)}
                      </p>
                      <p className="text-gray-600">{tx.amount} {batchCurrency}</p>
                    </div>
                    <Button
                      onClick={() => removeTransaction(tx.id)}
                      variant="ghost"
                      size="sm"
                      className="text-red-600 hover:text-red-700"
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex gap-3 pt-4">
            <Button
              onClick={generateDemoBatch}
              disabled={!batchTransactions.length || isSubmitting}
              variant="outline"
              className="flex-1 h-12"
            >
              <RefreshCw className="h-4 w-4 mr-2" />
              Prepare
            </Button>

            <Button
              onClick={handleSubmitBatch}
              disabled={!isConnected || !batchTransactions.length || isSubmitting}
              className="flex-1 h-12 bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700"
            >
              {isSubmitting ? (
                <>
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  Submitting...
                </>
              ) : (
                <>
                  <Send className="h-4 w-4 mr-2" />
                  Submit Batch (1 Wallet Confirmation)
                </>
              )}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* BATCH RESULTS SECTION */}
      {showResults && batchHistory.length > 0 && (
        <Card className="bg-white/90 backdrop-blur-sm border-2 border-green-200">
          <CardHeader className="bg-gradient-to-r from-green-50 to-emerald-50">
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-6 w-6 text-green-600" />
              Batch Performance Results
            </CardTitle>
          </CardHeader>

          <CardContent className="p-6 space-y-6">
            {/* Latest Batch Summary */}
            {batchHistory.length > 0 && (
              <div className="space-y-4">
                <h3 className="font-semibold text-lg">Latest Batch</h3>

                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
                    <p className="text-sm text-gray-600">Transactions</p>
                    <p className="text-2xl font-bold text-blue-600">
                      {batchHistory[batchHistory.length - 1]?.transactionCount || 0}
                    </p>
                  </div>

                  <div className="bg-green-50 p-4 rounded-lg border border-green-200">
                    <p className="text-sm text-gray-600">⚡ Effective TPS</p>
                    <p className="text-2xl font-bold text-green-600">
                      {batchHistory[batchHistory.length - 1]?.tps.toFixed(2) || '0'}
                    </p>
                  </div>

                  <div className="bg-purple-50 p-4 rounded-lg border border-purple-200">
                    <p className="text-sm text-gray-600">Total Time</p>
                    <p className="text-2xl font-bold text-purple-600">
                      {batchHistory[batchHistory.length - 1]?.totalTimeMs.toFixed(0) || '0'}ms
                    </p>
                  </div>

                  <div className="bg-orange-50 p-4 rounded-lg border border-orange-200">
                    <p className="text-sm text-gray-600">Network Latency</p>
                    <p className="text-2xl font-bold text-orange-600">
                      {batchHistory[batchHistory.length - 1]?.networkLatencyMs || '0'}ms
                    </p>
                  </div>
                </div>
              </div>
            )}

            {/* Key Insights */}
            <div className="bg-gradient-to-br from-yellow-50 to-orange-50 p-6 rounded-lg border border-yellow-200">
              <h4 className="font-semibold text-lg mb-3 flex items-center gap-2">
                <AlertCircle className="h-5 w-5 text-yellow-600" />
                Key Insights
              </h4>
              <ul className="space-y-2 text-sm text-gray-700">
                <li>
                  📊 <strong>Effective TPS:</strong> {batchHistory[batchHistory.length - 1]?.tps.toFixed(2) || '0'} tx/s
                  {batchHistory[batchHistory.length - 1]?.transactionCount && (
                    <span className="text-gray-600">
                      {' '}({batchHistory[batchHistory.length - 1]?.transactionCount} tx in{' '}
                      {batchHistory[batchHistory.length - 1]?.totalTimeMs.toFixed(0)}ms)
                    </span>
                  )}
                </li>
                <li>
                  🔗 <strong>Network Overhead:</strong>{' '}
                  {batchHistory[batchHistory.length - 1]?.networkLatencyMs || '0'}ms (~
                  {((
                    (batchHistory[batchHistory.length - 1]?.networkLatencyMs || 0) /
                    (batchHistory[batchHistory.length - 1]?.totalTimeMs || 1)
                  ) * 100).toFixed(1)}
                  %)
                </li>
                <li>
                  ✅ <strong>Validation:</strong> Only 1 wallet confirmation for{' '}
                  {batchHistory[batchHistory.length - 1]?.transactionCount || 0} transactions
                </li>
                <li>
                  💡 <strong>Use case:</strong> Perfect for privacy-preserving microtransactions to multiple services
                </li>
              </ul>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}