import { INITIAL_OVERLAY_STATE } from "next/dist/next-devtools/dev-overlay/shared";

const TARGETS = [
    'relayer',
    'zama',
];


function shouldTap(url: string){

    const u = url.toLowerCase();
    return TARGETS.some(t=> u.includes(t));
}


if (typeof window !== 'undefined'){

    const _fetch = window.fetch.bind(window);
    window.fetch = async (input: RequestInfo | URL, init? : RequestInit) => {
      const url = typeof input === 'string' ? input : (input as URL).toString();
      if (init?.method === 'POST' && shouldTap(url) && init.body){
        try {
            const clone = init.body instanceof ReadableStream
                ? '[stream]'
                : typeof init.body === 'string'
                ? init.body
                : '[non-string body]';
            console.log('[fetch-tap] POST', url, clone.slice?.(0, 4000));            
        } catch {}
      }
      return _fetch(input as any, init as any);
    };
}