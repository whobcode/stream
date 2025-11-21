# Deployment Checklist

Follow this step-by-step guide to deploy your Reolink NVR streaming solution.

## Pre-Deployment Checklist

- [ ] Node.js 18+ installed
- [ ] npm dependencies installed (`npm install`)
- [ ] Cloudflare account created
- [ ] Cloudflare Stream enabled on your account
- [ ] FFmpeg installed (for stream forwarding)

## Step 1: Configure Cloudflare

### 1.1 Get Your Account ID

1. Log in to https://dash.cloudflare.com
2. Copy your **Account ID** from the right sidebar
3. Save this for later

### 1.2 Create API Token

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click **"Create Token"**
3. Select **"Create Custom Token"**
4. Configure:
   - **Token name**: `Reolink Stream Worker`
   - **Permissions**:
     - Account → Stream → Edit
   - **Account Resources**: Include → Your Account
5. Click **"Continue to summary"** → **"Create Token"**
6. **COPY THE TOKEN** (you won't see it again!)

## Step 2: Create KV Namespace

Run these commands in your project directory:

```bash
# Create production namespace
npx wrangler kv:namespace create STREAM_CACHE

# Create preview namespace
npx wrangler kv:namespace create STREAM_CACHE --preview
```

**Save the output!** You'll get IDs like:
```
{ binding = "STREAM_CACHE", id = "abc123..." }
{ binding = "STREAM_CACHE", preview_id = "xyz789..." }
```

## Step 3: Update wrangler.jsonc

Edit `wrangler.jsonc` and update the KV namespace IDs:

```jsonc
"kv_namespaces": [
  {
    "binding": "STREAM_CACHE",
    "id": "abc123...",           // ← Paste production ID here
    "preview_id": "xyz789..."    // ← Paste preview ID here
  }
]
```

## Step 4: Set Secrets

Run these commands and enter the values when prompted:

```bash
# Set NVR password
npx wrangler secret put NVR_PASSWORD
# Enter: @codecam22

# Set Cloudflare API Token (from Step 1.2)
npx wrangler secret put CLOUDFLARE_API_TOKEN
# Paste: your-api-token-here

# Set Cloudflare Account ID (from Step 1.1)
npx wrangler secret put CLOUDFLARE_ACCOUNT_ID
# Paste: your-account-id-here
```

## Step 5: Test Locally (Optional)

```bash
# Start local development server
npx wrangler dev

# Open in browser:
# http://localhost:8787
```

Test that the page loads correctly before deploying.

## Step 6: Deploy to Cloudflare

```bash
# Deploy the Worker
npx wrangler deploy

# You'll get a URL like:
# https://reolink-stream-proxy.yourname.workers.dev
```

**Save this URL!**

## Step 7: Initialize Stream Inputs

1. Open your Worker URL in a browser
2. Click **"Initialize Streams"** button
3. Wait for success message (creates 7 Stream Live inputs)
4. **COPY ALL 7 RTMP INGEST URLS** from the page

The URLs will look like:
```
rtmps://live.cloudflare.com:443/live/MTQ0MTcjM3MjI...
```

## Step 8: Set Up Stream Forwarding

### Option A: Using the Setup Script (Easiest)

```bash
./setup-ffmpeg.sh \
  "rtmps://live.cloudflare.com:443/live/KEY1" \
  "rtmps://live.cloudflare.com:443/live/KEY2" \
  "rtmps://live.cloudflare.com:443/live/KEY3" \
  "rtmps://live.cloudflare.com:443/live/KEY4" \
  "rtmps://live.cloudflare.com:443/live/KEY5" \
  "rtmps://live.cloudflare.com:443/live/KEY6" \
  "rtmps://live.cloudflare.com:443/live/KEY7"
```

This creates systemd services (Linux) or shell scripts (macOS/Windows).

### Option B: Using Docker (Recommended for Production)

```bash
# The setup script creates docker-compose.yml
docker-compose up -d

# View logs
docker-compose logs -f
```

### Option C: Manual FFmpeg Commands

Run these in separate terminal windows:

```bash
# Camera 1
ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main \
  -c:v copy -c:a copy -f flv \
  "rtmps://live.cloudflare.com:443/live/KEY1"

# Camera 2
ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_02_main \
  -c:v copy -c:a copy -f flv \
  "rtmps://live.cloudflare.com:443/live/KEY2"

# Repeat for cameras 3-7
```

## Step 9: Verify Streaming

1. Wait 10-30 seconds for streams to start
2. Refresh your Worker URL
3. You should see all 7 camera feeds streaming live!

## Step 10: Monitor

### View Worker Logs

```bash
npx wrangler tail
```

### View Stream Status

Visit Cloudflare Dashboard:
https://dash.cloudflare.com/?to=/:account/stream/inputs

Check that all inputs show "Live" status.

### View FFmpeg Logs

**Docker:**
```bash
docker-compose logs -f camera1
```

**Systemd (Linux):**
```bash
journalctl --user -u reolink-camera-1.service -f
```

## Troubleshooting

### Streams not appearing?

1. **Check FFmpeg is running:**
   ```bash
   ps aux | grep ffmpeg
   # or
   docker-compose ps
   ```

2. **Test RTSP connection:**
   ```bash
   ffprobe rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main
   ```

3. **Check Cloudflare Stream inputs:**
   - Visit https://dash.cloudflare.com/?to=/:account/stream/inputs
   - All inputs should show "Live"

### Worker errors?

```bash
# View real-time logs
npx wrangler tail

# Check deployment status
npx wrangler deployments list
```

### FFmpeg connection issues?

- Verify NVR is accessible: `ping hwmnbn.myddns.me`
- Check firewall allows RTSP port 554
- Try different RTSP transport: `-rtsp_transport udp`

### KV namespace errors?

```bash
# List all KV namespaces
npx wrangler kv:namespace list

# Verify the IDs match wrangler.jsonc
```

## Post-Deployment

### Custom Domain (Optional)

1. Add a route in `wrangler.jsonc`:
   ```jsonc
   "routes": [
     {
       "pattern": "cameras.yourdomain.com/*",
       "zone_name": "yourdomain.com"
     }
   ]
   ```

2. Deploy: `npx wrangler deploy`

### Enable Access Control (Optional)

Protect your streams with Cloudflare Access:

1. Go to https://dash.cloudflare.com/?to=/:account/access
2. Create an Access policy for your Worker URL
3. Configure authentication (email, Google, etc.)

### Monitoring & Alerts

Set up monitoring for:
- FFmpeg process health
- Stream input status
- Worker error rates

## Costs Estimate

**Cloudflare Workers:** Free (100k requests/day)

**Cloudflare Stream:**
- Storage: ~$5/month per 1,000 minutes stored
- Delivery: ~$1 per 1,000 minutes delivered
- For 7 cameras recording 24/7: ~$35-50/month

## Success Criteria

- [ ] Worker deployed successfully
- [ ] All 7 Stream Live inputs created
- [ ] All 7 FFmpeg processes running
- [ ] All 7 camera feeds visible in browser
- [ ] No errors in Worker logs
- [ ] Streams play smoothly without buffering

## Support Resources

- Cloudflare Stream Docs: https://developers.cloudflare.com/stream/
- Cloudflare Workers Docs: https://developers.cloudflare.com/workers/
- Community Discord: https://discord.gg/cloudflaredev

---

**Deployment Date:** _________________

**Deployed By:** _________________

**Worker URL:** _________________

**Notes:**
