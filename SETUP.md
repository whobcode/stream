# Reolink NVR + Cloudflare Stream Setup Guide

## 📋 Prerequisites

- Cloudflare account with Workers and Stream enabled
- Reolink NVR accessible at: `hwmnbn.myddns.me:8080`
- Node.js and npm installed
- Wrangler CLI installed (already done ✅)

## 🔧 Setup Steps

### Step 1: Login to Cloudflare

```bash
npx wrangler login
```

This will open your browser to authenticate with Cloudflare.

### Step 2: Get Your Account ID

1. Go to https://dash.cloudflare.com
2. Select any domain or go to Workers & Pages
3. Copy your Account ID from the right sidebar
4. Update `wrangler.jsonc` with your Account ID (currently empty)

### Step 3: Create API Token

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use "Edit Cloudflare Workers" template
4. Add permissions:
   - **Workers Scripts:Edit**
   - **Stream:Edit** (important for Stream API)
   - **Account Settings:Read**
5. Create token and copy it

### Step 4: Create KV Namespace

```bash
# Create production namespace
npx wrangler kv namespace create STREAM_CACHE

# Create preview namespace for development
npx wrangler kv namespace create STREAM_CACHE --preview
```

**Update wrangler.jsonc** with the IDs returned:
```jsonc
"kv_namespaces": [
  {
    "binding": "STREAM_CACHE",
    "id": "your_production_id_here",
    "preview_id": "your_preview_id_here"
  }
]
```

### Step 5: Set Secrets

```bash
# NVR password
npx wrangler secret put NVR_PASSWORD
# When prompted, enter: @codecam22

# Cloudflare API token (from Step 3)
npx wrangler secret put CLOUDFLARE_API_TOKEN
# Paste the API token you created

# Cloudflare Account ID (from Step 2)
npx wrangler secret put CLOUDFLARE_ACCOUNT_ID
# Paste your account ID
```

### Step 6: Deploy the Worker

```bash
npx wrangler deploy
```

You'll get a URL like: `https://reolink-stream-proxy.your-subdomain.workers.dev`

### Step 7: Initialize Streams

1. Open the deployed URL in your browser
2. Click "Initialize Streams" button
3. This creates 7 Cloudflare Stream Live inputs
4. Copy the RTMP ingest URLs displayed for each camera

### Step 8: Configure Stream Forwarding

You need to forward your Reolink camera streams to Cloudflare Stream. There are two approaches:

#### Option A: Using FFmpeg (Recommended)

Install FFmpeg on a server that can access your NVR (24/7 uptime recommended):

```bash
# Install FFmpeg
sudo apt update && sudo apt install ffmpeg -y

# Create a script to forward all 7 cameras
nano stream_forwarder.sh
```

Add this content:

```bash
#!/bin/bash

# Replace these with the RTMP URLs from Step 7
RTMP_URL_1="rtmps://live.cloudflare.com/live/[YOUR_STREAM_KEY_1]"
RTMP_URL_2="rtmps://live.cloudflare.com/live/[YOUR_STREAM_KEY_2]"
RTMP_URL_3="rtmps://live.cloudflare.com/live/[YOUR_STREAM_KEY_3]"
RTMP_URL_4="rtmps://live.cloudflare.com/live/[YOUR_STREAM_KEY_4]"
RTMP_URL_5="rtmps://live.cloudflare.com/live/[YOUR_STREAM_KEY_5]"
RTMP_URL_6="rtmps://live.cloudflare.com/live/[YOUR_STREAM_KEY_6]"
RTMP_URL_7="rtmps://live.cloudflare.com/live/[YOUR_STREAM_KEY_7]"

# Forward each camera stream
ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main \
  -c:v copy -f flv "$RTMP_URL_1" &

ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_02_main \
  -c:v copy -f flv "$RTMP_URL_2" &

ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_03_main \
  -c:v copy -f flv "$RTMP_URL_3" &

ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_04_main \
  -c:v copy -f flv "$RTMP_URL_4" &

ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_05_main \
  -c:v copy -f flv "$RTMP_URL_5" &

ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_06_main \
  -c:v copy -f flv "$RTMP_URL_6" &

ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_07_main \
  -c:v copy -f flv "$RTMP_URL_7" &

wait
```

Make it executable and run:

```bash
chmod +x stream_forwarder.sh
./stream_forwarder.sh
```

#### Option B: Using Docker

Create a `docker-compose.yml`:

```yaml
version: '3.8'

services:
  camera1:
    image: jrottenberg/ffmpeg:latest
    restart: always
    command: >
      -rtsp_transport tcp
      -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main
      -c:v copy -f flv rtmps://live.cloudflare.com/live/[YOUR_STREAM_KEY_1]

  camera2:
    image: jrottenberg/ffmpeg:latest
    restart: always
    command: >
      -rtsp_transport tcp
      -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_02_main
      -c:v copy -f flv rtmps://live.cloudflare.com/live/[YOUR_STREAM_KEY_2]

  # Add camera3-7 following the same pattern...
```

Run with:

```bash
docker-compose up -d
```

## 🎉 Verification

1. Visit your Worker URL
2. All 7 camera streams should be visible
3. No login required - authentication happens server-side
4. Streams are publicly accessible to anyone with the URL

## 🔒 Security Considerations

Since the streams are public without authentication:

1. **Use obscure Worker name**: Change the worker name in `wrangler.jsonc` to something non-guessable
2. **Add basic auth** (optional): Implement HTTP Basic Authentication in the Worker
3. **Use Cloudflare Access**: Set up Cloudflare Access for the Worker route

## 🐛 Troubleshooting

### Streams not showing?
- Check that FFmpeg is running and can connect to the NVR
- Verify RTMP URLs are correct
- Check Worker logs: `npx wrangler tail`

### Authentication errors?
- Verify secrets are set correctly
- Check NVR_PASSWORD matches: `@codecam22`
- Ensure API token has Stream:Edit permission

### KV errors?
- Confirm KV namespace IDs are correct in `wrangler.jsonc`
- Make sure both production and preview IDs are set

## 📊 Monitoring

View Worker logs in real-time:

```bash
npx wrangler tail
```

Check Stream analytics:
https://dash.cloudflare.com/[YOUR_ACCOUNT_ID]/stream

## 🚀 Next Steps

1. Set up automatic restart for FFmpeg (systemd service)
2. Add SSL/TLS for Worker URL (use Custom Domain)
3. Implement authentication if needed
4. Set up monitoring/alerts for stream failures
5. Configure recording retention in Cloudflare Stream dashboard

## 📝 Notes

- Stream Live inputs remain active even when no video is being pushed
- Recordings are stored in Cloudflare Stream (check pricing)
- Each stream costs $5/1000 minutes delivered
- DVR feature allows viewers to seek back in live streams
