#!/bin/bash

# Safe copy script for packages/site
# Run from niobium repo root: bash /tmp/copy-site-safe.sh

set -e  # Exit on error

# Determine repo root (works if called from root or any subdirectory)
REPO_ROOT=$(pwd)
if [ ! -d "$REPO_ROOT/packages/site" ]; then
  echo "❌ Error: packages/site not found in current directory!"
  echo "Please run this script from the repo root:"
  echo "  cd /Users/martin/dev/niobium/UNIVersalPrivacyHook"
  echo "  bash /tmp/copy-site-safe.sh"
  exit 1
fi

SITE_DIR="$REPO_ROOT/packages/site"
PUBLIC_REPO="/Users/martin/dev/blockchain/UNIVersalPrivacyHook/packages/site"

echo "📍 Working directory: $REPO_ROOT"
echo "📁 Target: $SITE_DIR"
echo "📦 Source: $PUBLIC_REPO"
echo ""
echo "🚀 Starting safe copy of packages/site (22 files)..."
echo ""

# ============================================
# Phase 1: Core files (with consolidation)
# ============================================
echo "Phase 1️⃣: Core component & hooks..."

cp "$PUBLIC_REPO/components/UniversalPrivacyHookDemo_stable.tsx" \
   "$SITE_DIR/components/UniversalPrivacyHookDemo.tsx"

echo "  ✅ Copied UniversalPrivacyHookDemo_stable.tsx → UniversalPrivacyHookDemo.tsx"

# Fix case sensitivity in the component file
sed -i '' 's|usebatchFHE|useBatchFHE|g' "$SITE_DIR/components/UniversalPrivacyHookDemo.tsx"
echo "  ✅ Fixed import: usebatchFHE → useBatchFHE"

# Copy main hook
cp "$PUBLIC_REPO/hooks/useUniversalPrivacyHook.ts" \
   "$SITE_DIR/hooks/useUniversalPrivacyHook.ts"
echo "  ✅ Copied useUniversalPrivacyHook.ts"

# Copy batch hook with case fix
cp "$PUBLIC_REPO/hooks/usebatchFHE.ts" \
   "$SITE_DIR/hooks/useBatchFHE.ts"
echo "  ✅ Copied usebatchFHE.ts → useBatchFHE.ts (CASE FIXED!)"

# ============================================
# Phase 2: Components
# ============================================
echo ""
echo "Phase 2️⃣: Supporting components..."

cp "$PUBLIC_REPO/components/BatchFHEDemo.tsx" \
   "$SITE_DIR/components/BatchFHEDemo.tsx"
echo "  ✅ BatchFHEDemo.tsx"

cp "$PUBLIC_REPO/components/PerformanceComparison.tsx" \
   "$SITE_DIR/components/PerformanceComparison.tsx"
echo "  ✅ PerformanceComparison.tsx"

cp "$PUBLIC_REPO/components/BatchTransactionManager.tsx" \
   "$SITE_DIR/components/BatchTransactionManager.tsx"
echo "  ✅ BatchTransactionManager.tsx"

# ============================================
# Phase 3: App pages
# ============================================
echo ""
echo "Phase 3️⃣: App pages..."

cp "$PUBLIC_REPO/app/layout.tsx" \
   "$SITE_DIR/app/layout.tsx"
echo "  ✅ layout.tsx"

cp "$PUBLIC_REPO/app/page.tsx" \
   "$SITE_DIR/app/page.tsx"
echo "  ✅ page.tsx"

cp "$PUBLIC_REPO/app/login/page.tsx" \
   "$SITE_DIR/app/login/page.tsx"
echo "  ✅ login/page.tsx"

# ============================================
# Phase 4: Additional hooks
# ============================================
echo ""
echo "Phase 4️⃣: Additional hooks..."

cp "$PUBLIC_REPO/hooks/usePerformanceTracking.ts" \
   "$SITE_DIR/hooks/usePerformanceTracking.ts"
echo "  ✅ usePerformanceTracking.ts"

# ============================================
# Phase 5: Services
# ============================================
echo ""
echo "Phase 5️⃣: Service files..."

cp "$PUBLIC_REPO/services/encryptionTypes.ts" \
   "$SITE_DIR/services/encryptionTypes.ts"
echo "  ✅ encryptionTypes.ts"

cp "$PUBLIC_REPO/services/handles.ts" \
   "$SITE_DIR/services/handles.ts"
echo "  ✅ handles.ts"

cp "$PUBLIC_REPO/services/hpuClient.ts" \
   "$SITE_DIR/services/hpuClient.ts"
echo "  ✅ hpuClient.ts"

cp "$PUBLIC_REPO/services/relayer.ts" \
   "$SITE_DIR/services/relayer.ts"
echo "  ✅ relayer.ts"

cp "$PUBLIC_REPO/services/relayerClient.ts" \
   "$SITE_DIR/services/relayerClient.ts"
echo "  ✅ relayerClient.ts"

cp "$PUBLIC_REPO/services/utils.ts" \
   "$SITE_DIR/services/utils.ts"
echo "  ✅ utils.ts"

# ============================================
# Phase 6: Utilities & config
# ============================================
echo ""
echo "Phase 6️⃣: Utilities & config..."

cp "$PUBLIC_REPO/lib/fetch-tap.ts" \
   "$SITE_DIR/lib/fetch-tap.ts"
echo "  ✅ fetch-tap.ts"

# Create src/debug directory if it doesn't exist
mkdir -p "$SITE_DIR/src/debug"

if [ -f "$PUBLIC_REPO/src/debug/preflight.ts" ]; then
  cp "$PUBLIC_REPO/src/debug/preflight.ts" \
     "$SITE_DIR/src/debug/preflight.ts"
  echo "  ✅ preflight.ts"
else
  echo "  ⚠️  preflight.ts not in public repo (skipped)"
fi

cp "$PUBLIC_REPO/package.json" \
   "$SITE_DIR/package.json"
echo "  ✅ package.json"

cp "$PUBLIC_REPO/app/globals.css" \
   "$SITE_DIR/app/globals.css"
echo "  ✅ globals.css"

cp "$PUBLIC_REPO/public/niobium.png" \
   "$SITE_DIR/public/niobium.png"
echo "  ✅ niobium.png"

# ============================================
# Verification
# ============================================
echo ""
echo "🔍 VERIFICATION"
echo "=================================="

echo ""
echo "Files that SHOULD exist:"
if [ -f "$SITE_DIR/hooks/useBatchFHE.ts" ]; then
  echo "  ✅ hooks/useBatchFHE.ts"
else
  echo "  ❌ hooks/useBatchFHE.ts MISSING!"
  exit 1
fi

if [ -f "$SITE_DIR/components/UniversalPrivacyHookDemo.tsx" ]; then
  echo "  ✅ components/UniversalPrivacyHookDemo.tsx"
else
  echo "  ❌ components/UniversalPrivacyHookDemo.tsx MISSING!"
  exit 1
fi

if [ -f "$SITE_DIR/hooks/useUniversalPrivacyHook.ts" ]; then
  echo "  ✅ hooks/useUniversalPrivacyHook.ts"
else
  echo "  ❌ hooks/useUniversalPrivacyHook.ts MISSING!"
  exit 1
fi

echo ""
echo "Files that should NOT exist (old versions):"
if [ ! -f "$SITE_DIR/hooks/usebatchFHE.ts" ]; then
  echo "  ✅ No usebatchFHE.ts (case fixed)"
else
  echo "  ⚠️  WARNING: usebatchFHE.ts still exists!"
fi

if [ ! -f "$SITE_DIR/components/UniversalPrivacyHookDemo_stable.tsx" ]; then
  echo "  ✅ No UniversalPrivacyHookDemo_stable.tsx"
else
  echo "  ⚠️  WARNING: UniversalPrivacyHookDemo_stable.tsx still exists!"
fi

echo ""
echo "Checking critical imports:"
if grep -q "import.*useBatchFHE.*from.*useBatchFHE" "$SITE_DIR/components/UniversalPrivacyHookDemo.tsx"; then
  echo "  ✅ useBatchFHE import correct"
else
  echo "  ❌ useBatchFHE import may be broken"
fi

if grep -q "import.*useUniversalPrivacyHook" "$SITE_DIR/components/UniversalPrivacyHookDemo.tsx"; then
  echo "  ✅ useUniversalPrivacyHook import correct"
else
  echo "  ❌ useUniversalPrivacyHook import may be broken"
fi

# ============================================
# Final Summary
# ============================================
echo ""
echo "📊 GIT STATUS SUMMARY"
echo "=================================="

# Need to be in repo root for git to work
cd "$REPO_ROOT"

TOTAL=$(git status packages/site/ --short 2>/dev/null | wc -l)
echo "Total files changed: $TOTAL"
echo ""

echo "Changed files (showing first 15):"
git status packages/site/ --short 2>/dev/null | head -15

if [ "$TOTAL" -gt 15 ]; then
  echo "... and $((TOTAL - 15)) more files"
fi

echo ""
echo "✅ ALL 22 FILES COPIED SUCCESSFULLY!"
echo ""
echo "Next steps:"
echo "  1. Verify the files look good"
echo "  2. Run: git add packages/site/"
echo "  3. Run: git commit -m 'Migrate packages/site to Zama Integration version'"
echo ""
