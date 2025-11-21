#!/bin/bash
# Setup script for Reolink Stream Proxy
# This script helps configure the Worker and create necessary resources

set -e

echo "================================================"
echo "  Reolink Stream Proxy - Setup Script"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if wrangler is installed
if ! command -v npx &> /dev/null; then
    echo -e "${RED}Error: npm/npx not found. Please install Node.js first.${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Installing dependencies...${NC}"
npm install
echo -e "${GREEN}✓ Dependencies installed${NC}\n"

echo -e "${YELLOW}Step 2: Creating KV namespaces...${NC}"
echo "Creating production namespace..."
PROD_NS=$(npx wrangler kv:namespace create STREAM_CACHE 2>&1)
PROD_ID=$(echo "$PROD_NS" | grep -oP 'id = "\K[^"]+' || echo "")

echo "Creating preview namespace..."
PREVIEW_NS=$(npx wrangler kv:namespace create STREAM_CACHE --preview 2>&1)
PREVIEW_ID=$(echo "$PREVIEW_NS" | grep -oP 'id = "\K[^"]+' || echo "")

if [ -n "$PROD_ID" ] && [ -n "$PREVIEW_ID" ]; then
    echo -e "${GREEN}✓ KV namespaces created${NC}"
    echo "  Production ID: $PROD_ID"
    echo "  Preview ID: $PREVIEW_ID"
    echo ""
    echo -e "${YELLOW}Please update wrangler.jsonc with these IDs:${NC}"
    echo "  \"id\": \"$PROD_ID\","
    echo "  \"preview_id\": \"$PREVIEW_ID\""
else
    echo -e "${YELLOW}⚠ KV namespaces may already exist. Check wrangler.jsonc.${NC}"
fi
echo ""

echo -e "${YELLOW}Step 3: Configuring secrets...${NC}"
echo "You will be prompted to enter secrets. Press Enter to skip if already set."
echo ""

# Set NVR_PASSWORD
echo -e "${YELLOW}Setting NVR_PASSWORD...${NC}"
echo "Enter Reolink NVR password (@codecam22) or press Enter to skip:"
npx wrangler secret put NVR_PASSWORD || echo "Skipped or already set"

# Set CLOUDFLARE_ACCOUNT_ID
echo -e "\n${YELLOW}Setting CLOUDFLARE_ACCOUNT_ID...${NC}"
echo "Find your Account ID at: https://dash.cloudflare.com/"
echo "Enter your Cloudflare Account ID or press Enter to skip:"
npx wrangler secret put CLOUDFLARE_ACCOUNT_ID || echo "Skipped or already set"

# Set CLOUDFLARE_API_TOKEN
echo -e "\n${YELLOW}Setting CLOUDFLARE_API_TOKEN...${NC}"
echo "Create a token at: https://dash.cloudflare.com/profile/api-tokens"
echo "Required permissions: Account.Stream (Edit)"
echo "Enter your Cloudflare API Token or press Enter to skip:"
npx wrangler secret put CLOUDFLARE_API_TOKEN || echo "Skipped or already set"

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "================================================"
echo "  Next Steps:"
echo "================================================"
echo ""
echo "1. Update wrangler.jsonc with the KV namespace IDs shown above"
echo "2. Deploy the Worker:"
echo "   ${YELLOW}npm run deploy${NC}"
echo ""
echo "3. Visit your Worker URL and click 'Initialize Streams'"
echo ""
echo "4. Configure FFmpeg to forward streams (see README.md)"
echo "   Use the helper script:"
echo "   ${YELLOW}./create-stream-forwarder.sh${NC}"
echo ""
echo "================================================"
