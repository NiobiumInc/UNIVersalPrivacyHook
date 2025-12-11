"use client";

import { useState, useEffect } from 'react';
import { useUniversalPrivacyHook } from '../hooks/useUniversalPrivacyHook';
import { useMetaMaskEthersSigner } from '../hooks/metamask/useMetaMaskEthersSigner';
import { CONTRACTS } from '../config/contracts';
import { useFhevm } from '../fhevm/useFhevm';
import { ethers, formatUnits } from 'ethers';
import { useInMemoryStorage } from '../hooks/useInMemoryStorage';
import toast from 'react-hot-toast';
import { Button } from './ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Input } from './ui/input';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import React, {useRef} from 'react';
import {computeHandles } from '../services/handles';
import { fromHexString } from '@/services/utils';
import { BatchTransactionManager } from './BatchTransactionManager';
import { BatchTransactionManagerDUMMY } from './BatchTransactionManagerDUMMY';


import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from './ui/select';
import { 
  AlertCircle, 
  ArrowDownUp, 
  Clock, 
  Lock, 
  LogOut, 
  RefreshCw, 
  Wallet,
  Zap,
  Shield,
  Eye,
  DollarSign,
  Layers,
  Fuel
} from 'lucide-react';

declare global {
  interface Window {
    ethereum?: {
      request: (args: { method: string; params?: unknown[] }) => Promise<unknown>;
      isMetaMask?: boolean;
    };
  }
}

const DEBUG_FHE = true; // Set to false to disable debug logs

function debugLog(section: string, data: any) {
  if (!DEBUG_FHE) return;
  console.group(`[FHE DEBUG - ${section}]`);
  console.log(JSON.stringify(data, (key, value) =>
    typeof value === 'bigint' ? value.toString() : value
  , 2));
  console.groupEnd();
}


const VERIFYING_CONTRACT_INPUT_VERIFICATION =
  process.env.NEXT_PUBLIC_VERIFYING_CONTRACT_INPUT_VERIFICATION!;
const GATEWAY_CHAIN_ID =
  Number(process.env.NEXT_PUBLIC_GATEWAY_CHAIN_ID ?? 11155111);

function strToBytes(s: string): Uint8Array {
  if (s.startsWith('0x')) {
    const hex = s.slice(2);
    const out = new Uint8Array(hex.length / 2);
    for (let i = 0; i < out.length; i++) out[i] = parseInt(hex.slice(i*2, i*2+2), 16);
    return out;
  }
  let b64 = s.replace(/\s+/g, '');
  const mod = b64.length % 4;
  if (mod !== 0) b64 += '='.repeat(4 - mod);
  return new Uint8Array(Buffer.from(b64, 'base64'));
}





if (typeof window !== 'undefined' && !(window as any).__relayerFixed) {
  (window as any).__relayerFixed = true;

  const LOCAL_RELAYER = process.env.NEXT_PUBLIC_RELAYER_URL || 'http://localhost:8080';
  const ZAMA_RELAYER = 'https://relayer.testnet.zama.cloud';
  
  const originalFetch = window.fetch;

  window.fetch = async function(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
    const url = typeof input === 'string' ? input : 
                input instanceof URL ? input.href : 
                (input as Request).url;

    // Intercept relayer calls
    if (url.includes(ZAMA_RELAYER) || url.includes('/v1/input-proof')) {
      const newUrl = url.replace(ZAMA_RELAYER, LOCAL_RELAYER);
      
      // ⭐ LOG REQUEST
      if (init?.body && typeof init.body === 'string') {
        try {
          const body = JSON.parse(init.body);
          console.log('📤 [SDK → RELAYER REQUEST]', {
            hasCtHandles: !!body.ctHandles,
            ctHandlesCount: body.ctHandles?.length,
            ctHandles: body.ctHandles,
            hasCiphertext: !!body.ciphertextWithInputVerification,
            ciphertextLength: body.ciphertextWithInputVerification?.length,
          });
        }  catch (e) {
          console.error('Failed to parse body:', e);
        }
      }
      
      // Fix headers
      let cleanedInit = init;
      
      if (init) {
        const newHeaders = new Headers();
        
        if (init.headers) {
          if (init.headers instanceof Headers) {
            init.headers.forEach((value, key) => {
              if (key.toLowerCase() === 'content-type') {
                newHeaders.set(key, value.split(',')[0].trim());
              } else {
                newHeaders.set(key, value);
              }
            });
          } else if (Array.isArray(init.headers)) {
            init.headers.forEach(([key, value]) => {
              if (key.toLowerCase() === 'content-type') {
                newHeaders.set(key, value.split(',')[0].trim());
              } else {
                newHeaders.set(key, value);
              }
            });
          } else {
            Object.entries(init.headers).forEach(([key, value]) => {
              if (key.toLowerCase() === 'content-type' && typeof value === 'string') {
                newHeaders.set(key, value.split(',')[0].trim());
              } else {
                newHeaders.set(key, value as string);
              }
            });
          }
        }
        
        if (!newHeaders.has('Content-Type')) {
          newHeaders.set('Content-Type', 'application/json');
        }
        
        cleanedInit = {
          ...init,
          headers: newHeaders
        };
      }
      
      // Make request
      const response = await originalFetch(newUrl, cleanedInit);
      
      // ⭐ LOG RESPONSE
      try {
        const clonedResponse = response.clone();
        const responseData = await clonedResponse.json();
        console.group('📥 [RESPONSE FROM RELAYER]');
        console.log('handles relayer returned:', responseData.response?.handles);
        console.log('signatures count:', responseData.response?.signatures?.length);
        console.groupEnd();
      } catch (e) {
        console.error('Failed to parse response:', e);
      }
      
      return response;
    }

    return originalFetch(input, init);
  };

  console.log('✅ Relayer redirect installed');
}




export function UniversalPrivacyHookDemo() {
  const decUsdcRef = useRef<HTMLDivElement | null>(null);
  const { ethersSigner: signer, isConnected, connect, provider, chainId } = useMetaMaskEthersSigner();
  const hook = useUniversalPrivacyHook(); 
  const [isCorrectNetwork, setIsCorrectNetwork] = useState(false);
  
  // Helper function to get token symbol from address
  const getTokenSymbol = (address: string): string => {
    if (!address) return 'Unknown';
    const lowerAddress = address.toLowerCase();
    // Check for USDC addresses
    if (lowerAddress === CONTRACTS.MockUSDC?.toLowerCase() || 
        lowerAddress === CONTRACTS.EncryptedUSDC?.toLowerCase() ||
        lowerAddress === '0x59dd1a3bd1256503cdc023bfc9f10e107d64c3c1') {
      return 'eUSDC';
    }
    // Check for USDT addresses
    if (lowerAddress === CONTRACTS.MockUSDT?.toLowerCase() || 
        lowerAddress === CONTRACTS.EncryptedUSDT?.toLowerCase() ||
        lowerAddress === '0xb1d9519e953b8513a4754f9b33d37edba90c001d') {
      return 'eUSDT';
    }
    return 'Unknown';
  };
  
  // Check if we're on Sepolia
  useEffect(() => {
    setIsCorrectNetwork(chainId === 11155111); // Sepolia chainId
  }, [chainId]);
  
  const { storage: fhevmDecryptionSignatureStorage } = useInMemoryStorage();
  

  const EXTRA_RELAYER_SIGNERS =
    (process.env.NEXT_PUBLIC_RELAYER_SIGNER ?? "")
      .split(",").map(s => s.trim()).filter(Boolean);

  console.log("[frontend] domain vc:", VERIFYING_CONTRACT_INPUT_VERIFICATION, "gw:", GATEWAY_CHAIN_ID);
  console.log("[frontend] extra signers:", EXTRA_RELAYER_SIGNERS);

  
  const baseOpts = {
    provider:provider as any,
    chainId,
    enabled: isConnected && isCorrectNetwork,
    // ✅ Make sure your hook/SDK gets the SAME domain the relayer used
    gatewayUrl: 'http://localhost:8080',

    verifyingContractAddressInputVerification: '0x7048C39f048125eDa9d678AEbaDfB22F7900a29F',
    gatewayChainId: 55815,
    //verifyingContractAddressInputVerification: VERIFYING_CONTRACT_INPUT_VERIFICATION,
    //gatewayChainId: GATEWAY_CHAIN_ID,
    //coprocessorSigners: EXTRA_RELAYER_SIGNERS.length > 0 
    //  ? EXTRA_RELAYER_SIGNERS 
    //  : ['0x8d8adE312018b5d7207502579C82D312E6E5F843','0xA69268551b917EEbc1F3f5a76478F0ed8DBf8908'], // Fallback
    thresholdCoprocessorSigners: 0,
  };
  
  const { instance: fhevmInstance } = useFhevm(baseOpts as any); 

        // ⭐ Add this right after:
  useEffect(() => {
    if (fhevmInstance) {
      console.log('🔍 [FHEVM INSTANCE - ALL PROPERTIES]');
      console.log('Instance keys:', Object.keys(fhevmInstance));
      console.log('Instance:', fhevmInstance);
      
      // Try to find ACL address in different places
      const possibleAclAddresses = [
        (fhevmInstance as any).aclContractAddress,
        (fhevmInstance as any).aclAddress,
        (fhevmInstance as any)._config?.aclContractAddress,
        (fhevmInstance as any).config?.aclContractAddress,
        (fhevmInstance as any).contractAddress,
      ];
      
      console.log('Possible ACL addresses:', possibleAclAddresses.filter(Boolean));
      
      // Also check what methods are available
      console.log('Available methods:', Object.getOwnPropertyNames(Object.getPrototypeOf(fhevmInstance)));
    }
  }, [fhevmInstance]);


/*
  const { instance: fhevmInstance } = useFhevm({
    provider: provider as any,
    chainId: chainId,
    enabled: isConnected && isCorrectNetwork
  });
*/


  const { 
    deposit,
    withdraw, 
    submitIntent, 
    executeIntent,
    getEncryptedBalance,
    getRegularBalance,
    decryptBalance,
    fetchUserIntents,
    mintTokens,
    aggregateEncryptedBalance,
    loading
  } = useUniversalPrivacyHook();

  // State management
  const [depositCurrency, setDepositCurrency] = useState<'USDC' | 'USDT'>('USDC');
  const [depositAmount, setDepositAmount] = useState('');
  
  const [withdrawCurrency, setWithdrawCurrency] = useState<'USDC' | 'USDT'>('USDC');
  const [withdrawAmount, setWithdrawAmount] = useState('');
  const [withdrawRecipient, setWithdrawRecipient] = useState('');
  
  const [tokenIn, setTokenIn] = useState<'USDC' | 'USDT'>('USDC');
  const [tokenOut, setTokenOut] = useState<'USDC' | 'USDT'>('USDT');
  const [swapAmount, setSwapAmount] = useState('');
  
  const [submittedIntents, setSubmittedIntents] = useState<Array<{
    id: string;
    transactionHash: string;
    status: 'pending' | 'decrypted' | 'executed';
    amount?: string;
    tokenIn: string;
    tokenOut: string;
    timestamp: number;
    blockNumber?: number;
    batchId?: string | null;
    batchStatus?: string;
  }>>([]);
  const [isLoadingIntents, setIsLoadingIntents] = useState(false);
  const [processedIntents, setProcessedIntents] = useState<Set<string>>(new Set());
  
  // Balances
  const [balanceUSDC, setBalanceUSDC] = useState<string | null>(null);
  const [balanceUSDT, setBalanceUSDT] = useState<string | null>(null);
  const [encBalanceUSDC, setEncBalanceUSDC] = useState<string | null>(null);
  const [encBalanceUSDT, setEncBalanceUSDT] = useState<string | null>(null);
  const [decryptedBalanceUSDC, setDecryptedBalanceUSDC] = useState<string | null>(null);
  const [decryptedBalanceUSDT, setDecryptedBalanceUSDT] = useState<string | null>(null);
  const [isDecryptingUSDC, setIsDecryptingUSDC] = useState(false);
  const [isDecryptingUSDT, setIsDecryptingUSDT] = useState(false);
  
  // Loading states
  const [isSubmittingSwap, setIsSubmittingSwap] = useState(false);
  const [executingIntentId, setExecutingIntentId] = useState<string | null>(null);
  
  // Faucet state
  const [faucetAmount, setFaucetAmount] = useState('100');
  const [faucetCurrency, setFaucetCurrency] = useState<'USDC' | 'USDT'>('USDC');
  const [lastFaucetTime, setLastFaucetTime] = useState<{ [key: string]: number }>({});

  // HPU Aggregate timiing widget state
  const [hpuTiming, setHpuTiming] = useState<{ server: number | null; rtt: number | null; n: number } | null>(null);
  const [isAggregating, setIsAggregating] = useState(false);

  // Load processed intents from local storage
  useEffect(() => {
    const stored = localStorage.getItem('processedIntents');
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        setProcessedIntents(new Set(parsed));
      } catch {
        console.error('Failed to parse processed intents');
      }
    }
  }, []);
  
  // Save processed intents
  useEffect(() => {
    localStorage.setItem('processedIntents', JSON.stringify(Array.from(processedIntents)));
  }, [processedIntents]);

  // Load balances
  useEffect(() => {
    const loadBalances = async () => {
      const regularUSDC = await getRegularBalance('USDC');
      const regularUSDT = await getRegularBalance('USDT');
      setBalanceUSDC(regularUSDC);
      setBalanceUSDT(regularUSDT);
      
      const encUSDC = await getEncryptedBalance('USDC');
      const encUSDT = await getEncryptedBalance('USDT');
      
      if (encUSDC !== encBalanceUSDC) {
        setDecryptedBalanceUSDC(null);
      }
      if (encUSDT !== encBalanceUSDT) {
        setDecryptedBalanceUSDT(null);
      }
      
      setEncBalanceUSDC(encUSDC);
      setEncBalanceUSDT(encUSDT);
    };
    
    if (signer && isCorrectNetwork) {
      loadBalances();
      const interval = setInterval(loadBalances, 10000);
      return () => clearInterval(interval);
    }
  }, [signer, isCorrectNetwork, getEncryptedBalance, getRegularBalance, encBalanceUSDC, encBalanceUSDT]);

  // Load user intents
  useEffect(() => {
    const loadIntents = async () => {
      if (!signer || !isCorrectNetwork) return;
      
      setIsLoadingIntents(true);
      try {
        const intents = await fetchUserIntents();
        const formattedIntents = intents
          .filter(intent => !processedIntents.has(intent.id))
          .map(intent => ({
            id: intent.id,
            transactionHash: intent.transactionHash,
            status: 'pending' as const,
            tokenIn: intent.tokenIn,
            tokenOut: intent.tokenOut,
            timestamp: intent.timestamp * 1000,
            blockNumber: intent.blockNumber,
            batchId: intent.batchId,
            batchStatus: intent.batchStatus
          }));
        
        setSubmittedIntents(formattedIntents);
      } catch (err) {
        console.error('Failed to load intents:', err);
      } finally {
        setIsLoadingIntents(false);
      }
    };
    
    loadIntents();
  }, [signer, isCorrectNetwork, fetchUserIntents, processedIntents]);

  // Handlers
  const handleDecryptUSDC = async () => {
    console.log('[Decrypt] Button clicked usdc');
    console.warn('[Decrypt] precheck:', {
      signer: !!signer,
      fhevmInstance: !!fhevmInstance,
      fhevmDecryptionSignatureStorage: !!fhevmDecryptionSignatureStorage,
      encBalanceUSDC,
    });

    
    
    if (!fhevmInstance || !signer || !fhevmDecryptionSignatureStorage) return;
    if (!encBalanceUSDC || encBalanceUSDC === '0' || encBalanceUSDC === '0x0000000000000000000000000000000000000000000000000000000000000000') return;
    
    setIsDecryptingUSDC(true);
    try {
      const decryptedUSDC = await decryptBalance(
        encBalanceUSDC,
        CONTRACTS.EncryptedUSDC,
        fhevmInstance,
        fhevmDecryptionSignatureStorage
      );
      setDecryptedBalanceUSDC(decryptedUSDC);
      
      const decryptedValue = BigInt(decryptedUSDC as any);
      const formatted = formatUnits(decryptedValue,6)
      
      if (decUsdcRef.current){
        decUsdcRef.current.textContent = `${formatted} USDC`;
        setTimeout(() => {if (decUsdcRef.current) decUsdcRef.current.textContent = '';}, 5000);
      }
    } catch (err) {
      console.error('Error decrypting USDC balance:', err);
    } finally {
      setIsDecryptingUSDC(false);
    }

  };
  
  const handleDecryptUSDT = async () => {
    if (!fhevmInstance || !signer || !fhevmDecryptionSignatureStorage) return;
    if (!encBalanceUSDT || encBalanceUSDT === '0' || encBalanceUSDT === '0x0000000000000000000000000000000000000000000000000000000000000000') return;
    
    setIsDecryptingUSDT(true);
    try {
      const decryptedUSDT = await decryptBalance(
        encBalanceUSDT,
        CONTRACTS.EncryptedUSDT,
        fhevmInstance,
        fhevmDecryptionSignatureStorage
      );
      setDecryptedBalanceUSDT(decryptedUSDT);
    } catch (err) {
      console.error('Error decrypting USDT balance:', err);
    } finally {
      setIsDecryptingUSDT(false);
    }
  };

  const handleDeposit = async () => {
    try {
      const txHash = await deposit(depositCurrency, depositAmount);
      if (txHash) {
        toast.success(
          <div>
            Deposit successful!
            <a 
              href={`https://sepolia.etherscan.io/tx/${txHash}`} 
              target="_blank" 
              rel="noopener noreferrer"
              className="block text-xs text-blue-600 hover:underline mt-1"
            >
              View transaction →
            </a>
          </div>
        );
        setDepositAmount('');
      }
    } catch (err: any) {
      toast.error(err.message || 'Deposit failed');
    }
  };

  const handleWithdraw = async () => {
    try {
      const txHash = await withdraw(withdrawCurrency, withdrawAmount, withdrawRecipient || undefined);
      if (txHash) {
        toast.success(
          <div>
            Withdrawal successful!
            <a 
              href={`https://sepolia.etherscan.io/tx/${txHash}`} 
              target="_blank" 
              rel="noopener noreferrer"
              className="block text-xs text-blue-600 hover:underline mt-1"
            >
              View transaction →
            </a>
          </div>
        );
        setWithdrawAmount('');
        setWithdrawRecipient('');
      }
    } catch (err: any) {
      toast.error(err.message || 'Withdraw failed');
    }
  };



    const handleSubmitIntent = async () => {
          console.log('🔄 handleSubmitIntent called');

    if (isSubmittingSwap) {
        console.log('⚠️ Already submitting, ignoring');
        return;
    }
    setIsSubmittingSwap(true);
    
    try {
        // ===== STEP 1: Pre-flight checks =====
        debugLog('1. Pre-flight Checks', {
        fhevmInstance: !!fhevmInstance,
        signer: !!signer,
        tokenIn,
        tokenOut,
        swapAmount,
        encBalanceUSDC,
        encBalanceUSDT
        });

        if (!fhevmInstance || !signer) {
        toast.error('FHEVM not initialized');
        return;
        }
        
        const encBalance = tokenIn === 'USDC' ? encBalanceUSDC : encBalanceUSDT;
        if (!encBalance || encBalance === '0') {
        toast.error(`Deposit ${tokenIn} first`);
        return;
        }

        // ===== STEP 2: Environment validation =====
        const userAddr = ethers.getAddress(await signer.getAddress());
        const walletChainId = await (window as any).ethereum.request({ method: 'eth_chainId' });
        
        debugLog('2. Environment Variables', {
        VERIFYING_CONTRACT_INPUT_VERIFICATION,
        GATEWAY_CHAIN_ID,
        UniversalPrivacyHookAddress: CONTRACTS.UniversalPrivacyHook,
        userAddress: userAddr,
        walletChainId: parseInt(walletChainId, 16),
        expectedChainId: 11155111
        });

        // ===== STEP 3: Amount encryption setup =====
        const parsedAmount = ethers.parseUnits(swapAmount, 6);
        const amountBigInt = BigInt(parsedAmount.toString());
        
        debugLog('3. Amount Details', {
        swapAmountInput: swapAmount,
        parsedAmount: parsedAmount.toString(),
        amountBigInt: amountBigInt.toString(),
        amountInTokens: ethers.formatUnits(amountBigInt, 6)
        });

        // ===== STEP 4: Create encrypted input =====
        const input = fhevmInstance.createEncryptedInput(
        CONTRACTS.UniversalPrivacyHook,
        userAddr
        );


        console.log('🔍 [ENCRYPTED INPUT]', {
          input,
          inputKeys: Object.keys(input),
          inputPrototype: Object.getOwnPropertyNames(Object.getPrototypeOf(input)),
          // Try to access internal config
          _config: (input as any)._config,
          _aclAddress: (input as any)._aclAddress,
          config: (input as any).config,
        });


        // Track encryption method and bit width
        let encryptionMethod = 'unknown';
        let bitWidth = 0;
        
        if (typeof (input as any).add128 === "function") {
        (input as any).add128(amountBigInt);
        encryptionMethod = 'add128';
        bitWidth = 128;
        (window as any).__fhe_last_bits = 128;
        (window as any).__fhe_last_version = 0;
        } else if (typeof (input as any).add64 === "function") {
        (input as any).add64(Number(amountBigInt));
        encryptionMethod = 'add64';
        bitWidth = 64;
        (window as any).__fhe_last_bits = 64;
        (window as any).__fhe_last_version = 0;
        } else {
        (input as any).add32(Number(amountBigInt));
        encryptionMethod = 'add32';
        bitWidth = 32;
        (window as any).__fhe_last_bits = 32;
        (window as any).__fhe_last_version = 0;
        }

        debugLog('4. Encryption Method', {
        method: encryptionMethod,
        bitWidth,
        version: 0
        });


        console.log('🔍 [SDK ENCRYPTION PARAMS]', {
          contractForEncryption: CONTRACTS.UniversalPrivacyHook,
          userAddress: await signer.getAddress(),
          aclFromEnv: VERIFYING_CONTRACT_INPUT_VERIFICATION,
          gatewayChainId: GATEWAY_CHAIN_ID,
        });



        // ===== STEP 5: Encrypt and get handles =====
        let encrypted;
        try {
        encrypted = await input.encrypt();

        console.log('🔍 [FRONTEND AFTER ENCRYPT]', {
          handleComputed: '0x' + Array.from(encrypted.handles[0] as Uint8Array)
            .map(b => b.toString(16).padStart(2, '0'))
            .join(''),
          inputProofFirst32Bytes: '0x' + Array.from((encrypted.inputProof as Uint8Array).slice(0, 32))
            .map(b => b.toString(16).padStart(2, '0'))
            .join(''),
        });



        
        debugLog('5. Encryption Result', {
            handlesCount: encrypted.handles?.length,
            inputProofLength: encrypted.inputProof?.length,
            handle0Type: typeof encrypted.handles?.[0],
            handle0Constructor: encrypted.handles?.[0]?.constructor?.name
        });
        } catch (e: any) {
        console.error('[ENCRYPTION ERROR]', e);
        const resp = e?.response || e?.cause?.response;
        if (resp) {
            try {
            const text = await resp.text?.();
            debugLog('5. Relayer Error Response', {
                status: resp.status,
                statusText: resp.statusText,
                body: text
            });
            } catch {}
        }
        throw e;
        }

        // ===== STEP 6: Format handles and proof =====
        const encryptedHandle = '0x' + Array.from(encrypted.handles[0] as Uint8Array)
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
        
        const inputProofHex = '0x' + Array.from(encrypted.inputProof as Uint8Array)
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');

        debugLog('6. Formatted Data', {
        encryptedHandle,
        encryptedHandleLength: encryptedHandle.length,
        inputProofHex: inputProofHex.slice(0, 66) + '...',
        inputProofLength: inputProofHex.length
        });

        // ===== STEP 7: Submit to contract =====
        const tokenInContract = CONTRACTS[tokenIn === 'USDC' ? 'EncryptedUSDC' : 'EncryptedUSDT'];
        const tokenOutContract = CONTRACTS[tokenOut === 'USDC' ? 'EncryptedUSDC' : 'EncryptedUSDT'];
        
        debugLog('7. Contract Submission', {
        tokenIn,
        tokenOut,
        tokenInContract,
        tokenOutContract,
        hookContract: CONTRACTS.UniversalPrivacyHook
        });

        const result = await submitIntent(
        tokenIn,
        tokenOut,
        encryptedHandle,
        inputProofHex
        );
        
        debugLog('8. Submission Result', {
        success: !!result?.intentId,
        intentId: result?.intentId,
        txHash: result?.txHash
        });
        
        if (result?.intentId) {
        toast.success(
            <div>
            Intent submitted!
            {result.txHash && (
                <a 
                href={`https://sepolia.etherscan.io/tx/${result.txHash}`} 
                target="_blank" 
                rel="noopener noreferrer"
                className="block text-xs text-blue-600 hover:underline mt-1"
                >
                View transaction →
                </a>
            )}
            </div>
        );
        setSwapAmount('');
        }
    } catch (err: any) {
        debugLog('ERROR', {
        message: err.message,
        code: err.code,
        reason: err.reason,
        stack: err.stack?.split('\n').slice(0, 5)
        });
        toast.error(err.message || 'Failed to submit intent');
    } finally {
        setIsSubmittingSwap(false);
    }
    };


  const handleExecuteIntent = async (intentId: string) => {
    setExecutingIntentId(intentId);
    try {
      const txHash = await executeIntent(intentId);
      setProcessedIntents(prev => new Set([...prev, intentId]));
      setSubmittedIntents(prev => prev.filter(intent => intent.id !== intentId));
      toast.success(
        <div>
          Swap executed!
          <a 
            href={`https://sepolia.etherscan.io/tx/${txHash}`} 
            target="_blank" 
            rel="noopener noreferrer"
            className="block text-xs text-blue-600 hover:underline mt-1"
          >
            View transaction →
          </a>
        </div>
      );
    } catch (err: any) {
      console.error('Execute intent error:', err);
      if (err.message?.includes('0xe450d38c')) {
        toast.error('Intent may have already been executed or expired');
      } else if (err.message?.includes('insufficient')) {
        toast.error('Insufficient balance for swap');
      } else {
        toast.error(err.message || 'Failed to execute intent');
      }
    } finally {
      setExecutingIntentId(null);
    }
  };

  const switchToSepolia = async () => {
    if (!window.ethereum) return;
    
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0xaa36a7' }],
      });
    } catch (switchError: any) {
      if (switchError.code === 4902) {
        try {
          await window.ethereum.request({
            method: 'wallet_addEthereumChain',
            params: [{
              chainId: '0xaa36a7',
              chainName: 'Sepolia',
              nativeCurrency: {
                name: 'SepoliaETH',
                symbol: 'ETH',
                decimals: 18
              },
              rpcUrls: ['https://rpc.sepolia.org'],
              blockExplorerUrls: ['https://sepolia.etherscan.io/']
            }],
          });
        } catch (addError) {
          console.error('Failed to add Sepolia:', addError);
        }
      }
    }
  };

  // Not connected state
  if (!isConnected) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 relative">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <div className="mx-auto w-16 h-16 bg-orange-500/10 rounded-lg flex items-center justify-center mb-4">
              <Shield className="w-8 h-8 text-orange-500" />
            </div>
            <CardTitle className="text-2xl">Universal Privacy Hook</CardTitle>
            <CardDescription>
              Private DeFi trading powered by Fully Homomorphic Encryption
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={connect} className="w-full" size="lg" variant="default">
              <Wallet className="mr-2 h-5 w-5" />
              Connect Wallet
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Wrong network state
  if (isConnected && !isCorrectNetwork) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 relative">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <div className="mx-auto w-16 h-16 bg-orange-500/10 rounded-lg flex items-center justify-center mb-4">
              <AlertCircle className="w-8 h-8 text-orange-500" />
            </div>
            <CardTitle className="text-2xl">Wrong Network</CardTitle>
            <CardDescription>
              Please switch to Sepolia testnet to continue
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="bg-gradient-to-r from-orange-50 to-red-50/30 rounded-lg p-4 mb-4">
              <p className="text-sm text-gray-600 mb-1">Current network</p>
              <p className="font-semibold text-gray-900">
                {chainId === 31337 ? 'Localhost' : 
                 chainId === 1 ? 'Ethereum Mainnet' : 
                 `Chain ID: ${chainId}`}
              </p>
            </div>
            <Button onClick={switchToSepolia} className="w-full" size="lg" variant="default">
              Switch to Sepolia
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Main app
  return (
    <div className="relative min-h-screen p-3 sm:p-4 md:p-6">
      <div className="max-w-7xl mx-auto space-y-4 sm:space-y-6">
      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
        <Card className="bg-white/90 backdrop-blur-sm">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-gray-600">Total Value</CardTitle>
            <div className="p-2 bg-gradient-to-br from-green-400 to-emerald-500 rounded-lg">
              <DollarSign className="h-4 w-4 text-white" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              ${((parseFloat(balanceUSDC || '0') + parseFloat(balanceUSDT || '0')) * 1).toFixed(2)}
            </div>
          </CardContent>
        </Card>
        
        <Card className="bg-white/90 backdrop-blur-sm">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-gray-600">Gas Price</CardTitle>
            <div className="p-2 bg-gradient-to-br from-purple-400 to-pink-500 rounded-lg">
              <Fuel className="h-4 w-4 text-white" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">~5 Gwei</div>
          </CardContent>
        </Card>
      </div>

      {/* Balance Cards */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3 sm:gap-4">
        <Card className="bg-white/90 backdrop-blur-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Wallet className="h-5 w-5 text-gray-400" />
              <span>Regular Tokens</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-gradient-to-r from-orange-50 to-red-50/30 rounded-lg">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center text-white font-bold">
                  U
                </div>
                <span className="font-semibold">USDC</span>
              </div>
              <span className="text-xl font-bold font-mono">{balanceUSDC || '0.00'}</span>
            </div>
            <div className="flex items-center justify-between p-4 bg-gradient-to-r from-orange-50 to-red-50/30 rounded-lg">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center text-white font-bold">
                  T
                </div>
                <span className="font-semibold">USDT</span>
              </div>
              <span className="text-xl font-bold font-mono">{balanceUSDT || '0.00'}</span>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white/90 backdrop-blur-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Lock className="h-5 w-5 text-orange-500" />
              <span>Encrypted Tokens</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-gradient-to-r from-orange-50 to-red-50/30 rounded-lg">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-orange-500 rounded-full flex items-center justify-center text-white font-bold">
                  eU
                </div>
                <span className="font-semibold">eUSDC</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-xl font-bold font-mono">
                  {decryptedBalanceUSDC || (encBalanceUSDC && encBalanceUSDC !== '0' ? 
                    <span className="flex items-center gap-1">
                      <Lock className="w-4 h-4" />
                      <span className="text-sm text-gray-500">{Number(encBalanceUSDC).toExponential(2)}</span>
                    </span> : '0.00')}
                </span>
                {encBalanceUSDC && encBalanceUSDC !== '0' && !decryptedBalanceUSDC && (
                  <Button
                    onClick={handleDecryptUSDC}
                    disabled={isDecryptingUSDC}
                    size="sm"
                    variant="outline"
                  >
                    {isDecryptingUSDC ? <RefreshCw className="h-3 w-3 animate-spin" /> : <Eye className="h-3 w-3" />}
                  </Button>
                )}
              </div>
              <div ref={decUsdcRef} className='text-sm text-green-600 mt-1 font-semibold'></div>
            </div>
            <div className="flex items-center justify-between p-4 bg-gradient-to-r from-orange-50 to-red-50/30 rounded-lg">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-orange-500 rounded-full flex items-center justify-center text-white font-bold">
                  eT
                </div>
                <span className="font-semibold">eUSDT</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-xl font-bold font-mono">
                  {decryptedBalanceUSDT || (encBalanceUSDT && encBalanceUSDT !== '0' ? 
                    <span className="flex items-center gap-1">
                      <Lock className="w-4 h-4" />
                      <span className="text-sm text-gray-500">{Number(encBalanceUSDT).toExponential(2)}</span>
                    </span> : '0.00')}
                </span>
                {encBalanceUSDT && encBalanceUSDT !== '0' && !decryptedBalanceUSDT && (
                  <Button
                    onClick={handleDecryptUSDT}
                    disabled={isDecryptingUSDT}
                    size="sm"
                    variant="outline"
                  >
                    {isDecryptingUSDT ? <RefreshCw className="h-3 w-3 animate-spin" /> : <Eye className="h-3 w-3" />}
                  </Button>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Trading Interface */}
      <Card className="bg-white/90 backdrop-blur-sm border-orange-100">
        <CardHeader>
          <CardTitle className="text-3xl font-bold text-gray-900">
            Trading Operations
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="deposit" className="w-full">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="deposit" className="text-xs sm:text-sm md:text-base font-medium">Deposit</TabsTrigger>
              <TabsTrigger value="withdraw" className="text-xs sm:text-sm md:text-base font-medium">Withdraw</TabsTrigger>
              <TabsTrigger value="swap" className="text-xs sm:text-sm md:text-base font-medium px-1 sm:px-2">Private Swap</TabsTrigger>
            </TabsList>
            
            <TabsContent value="deposit" className="space-y-5 mt-6 bg-gradient-to-br from-orange-50 to-red-50/30 p-8 rounded-xl">
              <div className="space-y-2">
                <label className="text-base sm:text-lg font-semibold text-gray-800">Select Token</label>
                <div className="grid grid-cols-2 gap-2">
                  {(['USDC', 'USDT'] as const).map((token) => (
                    <Button
                      key={token}
                      onClick={() => setDepositCurrency(token)}
                      variant={depositCurrency === token ? "default" : "outline"}
                      className="h-14 text-lg font-medium"
                    >
                      <div className="flex items-center gap-2">
                        <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${
                          token === 'USDC' ? 'bg-blue-500' : 'bg-green-500'
                        }`}>
                          {token[0]}
                        </div>
                        {token}
                      </div>
                    </Button>
                  ))}
                </div>
              </div>
              
              <div className="space-y-2">
                <label className="text-base sm:text-lg font-semibold text-gray-800">Amount</label>
                <div className="relative">
                  <Input
                    type="text"
                    value={depositAmount}
                    onChange={(e) => setDepositAmount(e.target.value)}
                    placeholder="0.00"
                    className="pr-16 text-xl font-mono h-14"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500">
                    {depositCurrency}
                  </span>
                </div>
                <p className="text-base text-gray-600">
                  Available: {depositCurrency === 'USDC' ? balanceUSDC : balanceUSDT} {depositCurrency}
                </p>
              </div>
              
              <Button
                onClick={handleDeposit}
                disabled={loading || !depositAmount || parseFloat(depositAmount) <= 0}
                className="w-full h-14 text-lg font-medium"
                variant="default"
              >
                {loading ? <RefreshCw className="mr-2 h-4 w-4 animate-spin" /> : null}
                Deposit to Hook
              </Button>
            </TabsContent>
            
            <TabsContent value="withdraw" className="space-y-5 mt-6 bg-gradient-to-br from-orange-50 to-red-50/30 p-8 rounded-xl">
              <div className="space-y-2">
                <label className="text-base sm:text-lg font-semibold text-gray-800">Select Encrypted Token</label>
                <div className="grid grid-cols-2 gap-2">
                  {(['USDC', 'USDT'] as const).map((token) => (
                    <Button
                      key={token}
                      onClick={() => setWithdrawCurrency(token)}
                      variant={withdrawCurrency === token ? "default" : "outline"}
                      className="h-14 text-lg font-medium"
                    >
                      <div className="flex items-center gap-2">
                        <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${
                          token === 'USDC' ? 'bg-orange-500' : 'bg-orange-600'
                        }`}>
                          e{token[0]}
                        </div>
                        e{token}
                      </div>
                    </Button>
                  ))}
                </div>
              </div>
              
              <div className="space-y-2">
                <label className="text-base sm:text-lg font-semibold text-gray-800">Amount</label>
                <div className="relative">
                  <Input
                    type="text"
                    value={withdrawAmount}
                    onChange={(e) => setWithdrawAmount(e.target.value)}
                    placeholder="0.00"
                    className="pr-16 text-xl font-mono h-14"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500">
                    {withdrawCurrency}
                  </span>
                </div>
              </div>
              
              <div className="space-y-2">
                <label className="text-base sm:text-lg font-semibold text-gray-800">Recipient (Optional)</label>
                <Input
                  type="text"
                  value={withdrawRecipient}
                  onChange={(e) => setWithdrawRecipient(e.target.value)}
                  placeholder="0x..."
                />
              </div>
              
              <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
                <p className="text-sm text-orange-700">
                  ⚠️ Withdrawing will convert encrypted tokens back to regular tokens
                </p>
              </div>
              
              <Button
                onClick={handleWithdraw}
                disabled={loading || !withdrawAmount || parseFloat(withdrawAmount) <= 0}
                className="w-full"
                variant="default"
              >
                {loading ? <RefreshCw className="mr-2 h-4 w-4 animate-spin" /> : <LogOut className="mr-2 h-4 w-4" />}
                Withdraw from Hook
              </Button>
            </TabsContent>
            
            <TabsContent value="swap" className="space-y-4 sm:space-y-5 mt-4 sm:mt-6 bg-gradient-to-br from-orange-50 to-red-50/30 p-4 sm:p-6 md:p-8 rounded-xl">
              <div className="space-y-2">
                <label className="text-base sm:text-lg font-semibold text-gray-800">From (Encrypted)</label>
                <div className="flex gap-2">
                  <Input
                    type="text"
                    value={swapAmount}
                    onChange={(e) => setSwapAmount(e.target.value)}
                    placeholder="0.00"
                    className="flex-1 text-lg font-mono"
                  />
                  <Select value={tokenIn} onValueChange={(value) => setTokenIn(value as 'USDC' | 'USDT')}>
                    <SelectTrigger className="w-40 border-gray-700">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="USDC">
                        <div className="flex items-center gap-2">
                          <div className="w-6 h-6 bg-orange-500 rounded-full flex items-center justify-center text-white text-xs font-bold">
                            eU
                          </div>
                          eUSDC
                        </div>
                      </SelectItem>
                      <SelectItem value="USDT">
                        <div className="flex items-center gap-2">
                          <div className="w-6 h-6 bg-orange-600 rounded-full flex items-center justify-center text-white text-xs font-bold">
                            eT
                          </div>
                          eUSDT
                        </div>
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              
              <div className="flex justify-center">
                <Button
                  onClick={() => {
                    setTokenIn(tokenOut);
                    setTokenOut(tokenIn);
                  }}
                  variant="ghost"
                  size="icon"
                  className="rounded-full hover:bg-gray-800 border border-gray-700"
                >
                  <ArrowDownUp className="h-4 w-4" />
                </Button>
              </div>
              
              <div className="space-y-2">
                <label className="text-base sm:text-lg font-semibold text-gray-800">To (Encrypted)</label>
                <div className="flex gap-2">
                  <Input
                    type="text"
                    value={swapAmount}
                    readOnly
                    placeholder="0.00"
                    className="flex-1 text-lg font-mono opacity-70"
                  />
                  <Select value={tokenOut} onValueChange={(value) => setTokenOut(value as 'USDC' | 'USDT')}>
                    <SelectTrigger className="w-40 border-gray-700">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="USDC">
                        <div className="flex items-center gap-2">
                          <div className="w-6 h-6 bg-orange-500 rounded-full flex items-center justify-center text-white text-xs font-bold">
                            eU
                          </div>
                          eUSDC
                        </div>
                      </SelectItem>
                      <SelectItem value="USDT">
                        <div className="flex items-center gap-2">
                          <div className="w-6 h-6 bg-orange-600 rounded-full flex items-center justify-center text-white text-xs font-bold">
                            eT
                          </div>
                          eUSDT
                        </div>
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <p className="text-sm text-blue-700">
                  🔒 Your swap amount is encrypted using FHE
                </p>
              </div>
              
              <Button
                onClick={handleSubmitIntent}
                disabled={isSubmittingSwap || tokenIn === tokenOut || !swapAmount}
                className="w-full"
                variant="default"
              >
                {isSubmittingSwap ? <RefreshCw className="mr-2 h-4 w-4 animate-spin" /> : null}
                {isSubmittingSwap ? 'Processing...' : 'Submit Private Swap'}
              </Button>
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {/* Intent History */}
      <Card className="bg-white/90 backdrop-blur-sm">
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span className="flex items-center gap-2 text-2xl font-bold">
              <Clock className="h-6 w-6" />
              Intent History
            </span>
            <Button
              onClick={async () => {
                setIsLoadingIntents(true);
                const intents = await fetchUserIntents();
                const formattedIntents = intents
                  .filter(intent => !processedIntents.has(intent.id))
                  .map(intent => ({
                    id: intent.id,
                    status: intent.executed ? 'executed' as const : 
                            intent.decryptedAmount ? 'decrypted' as const : 
                            'pending' as const,
                    amount: intent.decryptedAmount || undefined,
                    tokenIn: intent.tokenIn,
                    tokenOut: intent.tokenOut,
                    timestamp: intent.timestamp * 1000,
                    blockNumber: intent.blockNumber
                  }));
                setSubmittedIntents(formattedIntents);
                setIsLoadingIntents(false);
              }}
              disabled={isLoadingIntents}
              size="sm"
              variant="outline"
            >
              <RefreshCw className={`h-4 w-4 ${isLoadingIntents ? 'animate-spin' : ''}`} />
            </Button>
          </CardTitle>
        </CardHeader>
        <CardContent className="p-6">
          {submittedIntents.length === 0 ? (
            <p className="text-center text-gray-600 py-8 text-xl font-medium">
              No pending intents
            </p>
          ) : (
            <div className="space-y-2">
              {submittedIntents.map((intent) => (
                <div key={intent.id} className="flex items-center justify-between p-5 bg-gradient-to-r from-blue-50 to-indigo-50/30 rounded-lg">
                  <div className="space-y-2 flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-semibold text-blue-600">
                        {getTokenSymbol(intent.tokenIn)}
                      </span>
                      <span className="text-gray-500">→</span>
                      <span className="font-semibold text-green-600">
                        {getTokenSymbol(intent.tokenOut)}
                      </span>
                    </div>
                    <a
                      href={`https://sepolia.etherscan.io/tx/${intent.transactionHash}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm font-mono text-blue-600 hover:text-blue-800 hover:underline block"
                    >
                      {intent.transactionHash.slice(0, 10)}...{intent.transactionHash.slice(-8)}
                    </a>
                    <p className="text-xs text-gray-400">Block: {intent.blockNumber}</p>
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    {intent.batchId && intent.batchId !== '0x0000000000000000000000000000000000000000000000000000000000000000' && (
                      <>
                        <p className="text-xs text-gray-400 font-mono">
                          Batch: {intent.batchId.slice(2, 5)}...{intent.batchId.slice(-3)}
                        </p>
                        <span className={`px-2 py-1 rounded text-xs font-semibold ${
                          intent.batchStatus === 'settled' ? 'bg-green-100 text-green-700' :
                          intent.batchStatus === 'finalized' ? 'bg-blue-100 text-blue-700' :
                          intent.batchStatus === 'processing' ? 'bg-yellow-100 text-yellow-700' :
                          'bg-gray-100 text-gray-600'
                        }`}>
                          {intent.batchStatus === 'settled' ? '✓ Settled' :
                           intent.batchStatus === 'finalized' ? '⏳ Finalized' :
                           intent.batchStatus === 'processing' ? '⚡ Processing' :
                           'Unknown'}
                        </span>
                      </>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Faucet */}
      <Card className="bg-white/90 backdrop-blur-sm">
        <CardHeader>
          <CardTitle className="text-2xl font-bold">
            Test Token Faucet
          </CardTitle>
          <CardDescription className="text-base">Get test tokens for demo (Max 100 tokens, 1 hour cooldown)</CardDescription>
        </CardHeader>
        <CardContent className="p-6">
          <div className="space-y-4 sm:space-y-5 bg-gradient-to-br from-orange-50 to-red-50/30 p-4 sm:p-6 rounded-lg">
          <div className="space-y-2">
            <label className="text-base sm:text-lg font-semibold text-gray-800">Select Token</label>
            <div className="grid grid-cols-2 gap-2">
              {(['USDC', 'USDT'] as const).map((token) => (
                <Button
                  key={token}
                  onClick={() => setFaucetCurrency(token)}
                  variant={faucetCurrency === token ? "default" : "outline"}
                  className="h-12"
                >
                  <div className="flex items-center gap-2">
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${
                      token === 'USDC' ? 'bg-blue-500' : 'bg-green-500'
                    }`}>
                      {token[0]}
                    </div>
                    {token}
                  </div>
                </Button>
              ))}
            </div>
          </div>
          
          <div className="space-y-2">
            <label className="text-base sm:text-lg font-semibold text-gray-800">Amount (max 100)</label>
            <div className="relative">
              <Input
                type="number"
                value={faucetAmount}
                onChange={(e) => {
                  const value = Math.min(100, Math.max(0, parseInt(e.target.value) || 0));
                  setFaucetAmount(value.toString());
                }}
                placeholder="0"
                className="pr-16 text-lg font-mono"
                max="100"
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground">
                {faucetCurrency}
              </span>
            </div>
            <p className="text-base text-gray-600">
              {parseInt(faucetAmount) > 100 ? 
                <span className="text-orange-600">Maximum 100 tokens per request</span> : 
                `Mint up to 100 test ${faucetCurrency} tokens`
              }
            </p>
          </div>
          

          <div className="mt-3 space-y-2">
            <Button
              onClick={async () => {
                if (!aggregateEncryptedBalance) return;

                try {
                  setIsAggregating(true);

                  // Use whichever encrypted handles you currently have (USDC/USDT)
                  const handles: string[] = [];
                  if (encBalanceUSDC && encBalanceUSDC !== '0') handles.push(encBalanceUSDC);
                  if (encBalanceUSDT && encBalanceUSDT !== '0') handles.push(encBalanceUSDT);

                  if (handles.length === 0) {
                    toast.error('No encrypted balances to aggregate.');
                    return;
                  }

                  // Token address only matters if you later decrypt the aggregate with SDK.
                  const tokenAddr = CONTRACTS.EncryptedUSDC;

                  const res: any = await aggregateEncryptedBalance(handles, tokenAddr);
                  // Expect shape from /compute_vec: { success, result, count, error, computation_time_ms }
                  if (!res || res.success === false) {
                    toast.error(res?.error || 'HPU aggregation failed');
                    return;
                  }

                  setHpuTiming({
                    server: res.computation_time_ms ?? null,
                    rtt: null,          // we didn’t measure RTT here
                    n: res.count ?? handles.length,
                  });

                  toast.success('HPU aggregate finished.');
                } catch (e: any) {
                  toast.error(String(e.message || e));
                } finally {
                  setIsAggregating(false);
                }
              }}
              disabled={isAggregating}
              variant="outline"
            >
              {isAggregating ? <RefreshCw className="h-4 w-4 mr-2 animate-spin" /> : null}
              HPU Aggregate
            </Button>

            {hpuTiming && (
              <div className="text-xs opacity-80 mt-2">
                HPU compute: {hpuTiming.server ?? '—'} ms (server)
                {hpuTiming.rtt !== null ? <> · {Math.round(hpuTiming.rtt)} ms RTT</> : null}
                {' '}· n={hpuTiming.n}
              </div>
            )}
          </div>


          <Button
            onClick={async () => {
              try {
                const now = Date.now();
                const lastTime = lastFaucetTime[faucetCurrency] || 0;
                const timeDiff = now - lastTime;
                const oneHour = 60 * 60 * 1000;
                
                if (timeDiff < oneHour) {
                  const remainingMinutes = Math.ceil((oneHour - timeDiff) / 60000);
                  toast.error(`Please wait ${remainingMinutes} minutes before requesting ${faucetCurrency} again`);
                  return;
                }
                
                const txHash = await mintTokens(faucetCurrency, faucetAmount);
                setLastFaucetTime({ ...lastFaucetTime, [faucetCurrency]: now });
                if (txHash) {
                  toast.success(
                    <div>
                      Minted {faucetAmount} {faucetCurrency}!
                      <a 
                        href={`https://sepolia.etherscan.io/tx/${txHash}`} 
                        target="_blank" 
                        rel="noopener noreferrer"
                        className="block text-xs text-blue-600 hover:underline mt-1"
                      >
                        View transaction →
                      </a>
                    </div>
                  );
                } else {
                  toast.success(`Minted ${faucetAmount} ${faucetCurrency}`);
                }
              } catch (err: any) {
                toast.error(err.message || 'Mint failed');
              }
            }}
            disabled={loading || !faucetAmount || parseInt(faucetAmount) > 100}
            className="w-full h-14 text-lg font-medium"
            variant="default"
          >
            {loading ? <RefreshCw className="mr-2 h-4 w-4 animate-spin" /> : <Zap className="mr-2 h-4 w-4" />}
            Mint {faucetAmount || '0'} Test Tokens
          </Button>
          </div>
        </CardContent>
      </Card>

      {/* NEW: Batch Transactions Component */}
      <BatchTransactionManager 
        hook={hook}
        isConnected={isConnected}
        signer={signer}
      />
      </div>
    </div>
  );
}
