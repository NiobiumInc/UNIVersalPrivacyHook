//packacges/site/services/relayer.ts
const BASE = process.env.NEXT_PUBLIC_RELAYER_URL;

function assertBase(){
    if(!BASE) throw new Error("NEXT_PUBLIC_RELAYER_URL is not set");
}


export async function relayerHealth(){
    assertBase();
    const r = await fetch('${BASE}/health');
    if (!r.ok) throw new Error('Relayer health $(r.status)');
    return r.json();
}


// Ask relayer to produce input + inputProof for a swap amount
// We can later include poolID , token In/Out if relayer needs them

export async function relayerEncryptAmount(params:  {
    chainId: number;
    user: string;           // Address used for EIP 712 if needed
    hook: string;           // UniversalPrivacyHook Address
    tokenIn: string;        // ERC-20 address
    amount: string;         // decimal or bigint as string

})  {
    assertBase();
    const r = await fetch('${BASE}/encrypt amount', {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify(params),
    });
    if (!r.ok) throw new Error('Relayer encrypt $(r.status)');
    return r.json() as Promise<{ handle: string; inputProof: string }>;
}



// Ask relayer to decrypt and encrypted balance handle/cyphertext to a plaintext string
// If your relayer expects a wallet signature (recommend) pass it too

export async function relayerUserDecrypt(params:  {
    chainId: number;
    user: string;           // Address used for EIP 712 if needed
    token: string;          // ERC-20 address
    cyphertextHex: string;  // the enc balance/handle as hex 
    eip712?: { domain: any; types: any; message: any; signature: string };
})  {
    assertBase();
    const r = await fetch('${BASE}/user-decrypt', {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify(params),
    });
    if (!r.ok) throw new Error('Relayer encrypt $(r.status)');
    return r.json() as Promise<{ plaintext: string }>;
}








