import { createInstance, SepoliaConfig } from '@zama-fhe/relayer-sdk/node';

// Set these to something sensible for your test.
// - contractAddress: an address of a contract that will consume FHE.fromExternal (any EVM address works for encryption/registration)
// - userAddress: your EOA on Sepolia (the "importer")
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS ?? '0x9078D30062A5b50621A5635Ed75e1EA0449F0080';
const USER_ADDRESS     = process.env.USER_ADDRESS     ?? '0xE96144f453EE63cF302431fF666aA954aC98f57b';

function toHex(u8) { return '0x' + Buffer.from(u8).toString('hex'); }
function toHexArray(arr) { return arr.map(toHex); }

async function main() {
  console.log('Connecting to Zama relayer with SepoliaConfig...');
  const fhe = await createInstance({ ...SepoliaConfig });

  // Optional: show which relayer/chain we’re about to use
  console.log('Relayer URL:', SepoliaConfig.relayerUrl, 'chainId:', SepoliaConfig.chainId, 'gatewayChainId:', SepoliaConfig.gatewayChainId);

  console.log('Creating encrypted input buffer...');
  const buf = fhe.createEncryptedInput(CONTRACT_ADDRESS, USER_ADDRESS);

  console.log('Adding values to buffer...');
  // Add two 64-bit ints (BigInt required). You can add others: add8/add16/add32/add128/add256/addBool/addAddress.
  buf.add64(BigInt(42));
  buf.add64(BigInt(7));

  console.log('Encrypting & registering via relayer...');
  const { handles, inputProof } = await buf.encrypt();

  // ✅ Print hex for pasting into the swap script
  const handlesHex = toHexArray(handles);
  const inputProofHex = toHex(inputProof);
  console.log('handlesHex:', handlesHex);
  console.log('InputProofHex:', inputProofHex);

  // (Optional) Try decryption. This will often be denied unless ACL allows it.
  try {
    // v0.2 does decryption via the decryption API sections; often you’ll call methods under fhe.decrypt.*
    // Many setups restrict user decryption, so expect this to fail unless ACL is configured for your USER_ADDRESS.
    const result = await fhe.decrypt.handles(handles);
    console.log('Decryption result:', result);
  } catch (e) {
    console.log('Decrypt likely not permitted (expected in many setups):', String(e));
  }
}

main().catch((e) => {
  console.error('Test failed:', e);
  process.exit(1);
});
