//import createHash from 'keccak';
console.log('[handles.ts] client version loaded', { 
  at: new Date().toISOString()});

import {keccak256} from "ethers";

import { ENCRYPTION_TYPES } from './encryptionTypes';
import { fromHexString } from './utils';

type EncryptionBitwidths = keyof typeof ENCRYPTION_TYPES;

const MAX_UINT64 = BigInt('18446744073709551615'); // 2^64 - 1
const RAW_CT_HASH_DOMAIN_SEPARATOR = 'ZK-w_rct';
const HANDLE_HASH_DOMAIN_SEPARATOR = 'ZK-w_hdl';


// tiny helper: concat → keccak256 → Buffer(32)
const keccakBuf = (...parts: (Uint8Array | Buffer)[]) =>
  Buffer.from(keccak256(Buffer.concat(parts.map(p => Buffer.from(p)))).slice(2), "hex");


export const computeHandles = (
  ciphertextWithZKProof: Uint8Array,
  bitwidths: EncryptionBitwidths[],
  aclContractAddress: string,
  chainId: number,
  ciphertextVersion: number,
) => {
  // Should be identical to:
  // https://github.com/zama-ai/fhevm-backend/blob/bae00d1b0feafb63286e94acdc58dc88d9c481bf/fhevm-engine/zkproof-worker/src/verifier.rs#L301
  
  const blob_hash = Buffer.from(
    keccak256(
      Buffer.concat([
        Buffer.from(RAW_CT_HASH_DOMAIN_SEPARATOR),
        Buffer.from(ciphertextWithZKProof),
      ])
    ).slice(2),
    "hex"
  );
  /*
  const blob_hash = createHash('keccak256')
    .update(Buffer.from(RAW_CT_HASH_DOMAIN_SEPARATOR))
    .update(Buffer.from(ciphertextWithZKProof))
    .digest();
  */
  
    const aclContractAddress20Bytes = Buffer.from(
    fromHexString(aclContractAddress),
  );


  const hex = chainId.toString(16).padStart(64, '0'); // 64 hex chars = 32 bytes
  const chainId32Bytes = Buffer.from(hex, 'hex');

  const handles = bitwidths.map((bitwidth, encryptionIndex) => {
    const encryptionType = ENCRYPTION_TYPES[bitwidth];
    const encryptionIndexByte = Buffer.from([encryptionIndex & 0xff]);
  


      // was: createHash('keccak256')…update(…)…digest()
  const handleHash = keccakBuf(
    Buffer.from(HANDLE_HASH_DOMAIN_SEPARATOR),
    blob_hash,                         // from your earlier ethers.keccak256 conversion
    encryptionIndexByte,
    Buffer.from([Number(encryptionType)]),
    aclContractAddress20Bytes,
    chainId32Bytes
  );



  /*
    const handleHash = createHash('keccak256')
      .update(Buffer.from(HANDLE_HASH_DOMAIN_SEPARATOR))
      .update(blob_hash)
      .update(encryptionIndex1Byte)
      .update(aclContractAddress20Bytes)
      .update(chainId32Bytes)
      .digest();

  */

    const dataInput = new Uint8Array(32);
    dataInput.set(handleHash, 0);

    // Check if chainId exceeds 8 bytes
    if (BigInt(chainId) > MAX_UINT64) {
      throw new Error('ChainId exceeds maximum allowed value (8 bytes)'); // fhevm assumes chainID is only taking up to 8 bytes
    }

    const chainId8Bytes = fromHexString(hex).slice(24, 32);
    dataInput[21] = encryptionIndex & 0xff;
    dataInput.set(chainId8Bytes, 22);
    dataInput[30] = Number(encryptionType) & 0xff;
    dataInput[31] = ciphertextVersion & 0xff;

    return dataInput;
  });
  return handles;
};
