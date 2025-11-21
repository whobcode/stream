#!/bin/bash

# Setup Verification Script
# Checks if all prerequisites are met before deployment

echo "======================================"
echo "Reolink Stream Setup Verification"
echo "======================================"
echo ""

ERRORS=0
WARNINGS=0

# Check Node.js
echo -n "Checking Node.js... "
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo "✓ $NODE_VERSION"
else
    echo "✗ Not installed"
    echo "  Install from: https://nodejs.org/"
    ERRORS=$((ERRORS + 1))
fi

# Check npm
echo -n "Checking npm... "
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    echo "✓ v$NPM_VERSION"
else
    echo "✗ Not installed"
    ERRORS=$((ERRORS + 1))
fi

# Check Wrangler
echo -n "Checking Wrangler... "
if command -v wrangler &> /dev/null; then
    WRANGLER_VERSION=$(wrangler --version)
    echo "✓ $WRANGLER_VERSION"
else
    echo "✗ Not installed"
    echo "  Run: npm install"
    ERRORS=$((ERRORS + 1))
fi

# Check FFmpeg (optional but recommended)
echo -n "Checking FFmpeg... "
if command -v ffmpeg &> /dev/null; then
    FFMPEG_VERSION=$(ffmpeg -version | head -n1 | cut -d' ' -f3)
    echo "✓ version $FFMPEG_VERSION"
else
    echo "⚠ Not installed (required for streaming)"
    echo "  Install: apt-get install ffmpeg (Linux) or brew install ffmpeg (macOS)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Docker (optional)
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    echo "✓ version $DOCKER_VERSION"
else
    echo "⚠ Not installed (optional)"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "======================================"
echo "Project Files"
echo "======================================"
echo ""

# Check required files
FILES=(
    "wrangler.jsonc"
    "package.json"
    "src/index.ts"
    "src/public/index.html"
    "tsconfig.json"
)

for FILE in "${FILES[@]}"; do
    echo -n "Checking $FILE... "
    if [ -f "$FILE" ]; then
        echo "✓"
    else
        echo "✗ Missing"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "======================================"
echo "Dependencies"
echo "======================================"
echo ""

# Check node_modules
echo -n "Checking node_modules... "
if [ -d "node_modules" ]; then
    echo "✓ Installed"
else
    echo "✗ Not installed"
    echo "  Run: npm install"
    ERRORS=$((ERRORS + 1))
fi

# Check package versions
echo -n "Checking @cloudflare/workers-types... "
if npm list @cloudflare/workers-types &> /dev/null; then
    echo "✓"
else
    echo "✗ Missing"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Checking typescript... "
if npm list typescript &> /dev/null; then
    echo "✓"
else
    echo "✗ Missing"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "======================================"
echo "Configuration"
echo "======================================"
echo ""

# Check wrangler.jsonc
echo "Checking wrangler.jsonc configuration..."

if grep -q '"placeholder_id"' wrangler.jsonc; then
    echo "  ⚠ KV namespace IDs not updated"
    echo "    Run: npx wrangler kv:namespace create STREAM_CACHE"
    WARNINGS=$((WARNINGS + 1))
else
    echo "  ✓ KV namespace IDs configured"
fi

if grep -q '"NVR_HOST"' wrangler.jsonc; then
    echo "  ✓ NVR_HOST configured"
else
    echo "  ✗ NVR_HOST not configured"
    ERRORS=$((ERRORS + 1))
fi

if grep -q '"NVR_USERNAME"' wrangler.jsonc; then
    echo "  ✓ NVR_USERNAME configured"
else
    echo "  ✗ NVR_USERNAME not configured"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "======================================"
echo "Network Tests"
echo "======================================"
echo ""

# Test NVR connectivity
echo -n "Testing NVR connectivity (hwmnbn.myddns.me)... "
if ping -c 1 -W 3 hwmnbn.myddns.me &> /dev/null; then
    echo "✓ Reachable"
else
    echo "⚠ Not reachable (may affect streaming)"
    WARNINGS=$((WARNINGS + 1))
fi

# Test RTSP port (if nmap available)
if command -v nc &> /dev/null; then
    echo -n "Testing RTSP port 554... "
    if timeout 3 nc -zv hwmnbn.myddns.me 554 &> /dev/null; then
        echo "✓ Open"
    else
        echo "⚠ Cannot connect (firewall?)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""
echo "======================================"
echo "Summary"
echo "======================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✓ All checks passed! Ready to deploy."
    echo ""
    echo "Next steps:"
    echo "  1. Create KV namespace: npx wrangler kv:namespace create STREAM_CACHE"
    echo "  2. Set secrets: npx wrangler secret put NVR_PASSWORD"
    echo "  3. Deploy: npx wrangler deploy"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠ $WARNINGS warning(s) - you can proceed but review warnings above"
    echo ""
    exit 0
else
    echo "✗ $ERRORS error(s), $WARNINGS warning(s)"
    echo ""
    echo "Please fix the errors above before deploying."
    echo ""
    exit 1
fi
