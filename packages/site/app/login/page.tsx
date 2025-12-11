'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

// new to check
import '@/lib/fetch-tap';
console.log('[fetch-tap] loaded');


export default function LoginPage() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to home page immediately
    router.replace('/');
  }, [router]);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <p>Redirecting to home...</p>
      </div>
    </div>
  );
}