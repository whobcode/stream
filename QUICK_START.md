# Quick Start Guide

Get your Reolink camera streams online in 5 minutes.

## Prerequisites

- ✅ Cloudflare account
- ✅ Node.js 18+ installed
- ✅ Reolink NVR accessible at `hwmnbn.myddns.me:8080`

## 1. Install Dependencies

```bash
cd /home/marswc/code/stream
npm install
```

## 2. Create KV Namespace

```bash
npx wrangler kv:namespace create STREAM_CACHE
npx wrangler kv:namespace create STREAM_CACHE --preview
```

Copy the IDs and update `wrangler.jsonc`:

```jsonc
"kv_namespaces": [
  {
    "binding": "STREAM_CACHE",
    "id": "<YOUR_PRODUCTION_ID>",
    "preview_id": "<YOUR_PREVIEW_ID>"
  }
]
```

## 3. Set Secrets

```bash
# Get your Account ID from: https://dash.cloudflare.com
# Create API Token at: https://dash.cloudflare.com/profile/api-tokens
# Permissions needed: Stream:Edit

npx wrangler secret put NVR_PASSWORD
# Enter: @codecam22

npx wrangler secret put CLOUDFLARE_API_TOKEN
# Paste your API token

npx wrangler secret put CLOUDFLARE_ACCOUNT_ID
# Paste your Account ID
```

## 4. Deploy

```bash
npx wrangler deploy
```

You'll get a URL like: `https://reolink-stream-proxy.yourname.workers.dev`

## 5. Initialize Streams

1. Open your Worker URL in browser
2. Click **"Initialize Streams"**
3. Copy all 7 RTMP ingest URLs

## 6. Start Streaming

### Quick Method (Shell Scripts)

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

### Production Method (Docker)

```bash
# Setup script creates docker-compose.yml
docker-compose up -d
```

## 7. View Streams

Visit your Worker URL - all 7 cameras should be streaming live! 🎥

## Commands Reference

```bash
# Local development
npx wrangler dev

# Deploy
npx wrangler deploy

# View logs
npx wrangler tail

# List deployments
npx wrangler deployments list

# List KV namespaces
npx wrangler kv:namespace list

# View FFmpeg logs (Docker)
docker-compose logs -f camera1

# Stop streams
docker-compose down
```

## Troubleshooting

**No streams visible?**
- Check FFmpeg is running: `docker-compose ps` or `ps aux | grep ffmpeg`
- Check Stream dashboard: https://dash.cloudflare.com/?to=/:account/stream/inputs

**Worker errors?**
- View logs: `npx wrangler tail`
- Check secrets are set: All 3 secrets (NVR_PASSWORD, CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID)

**FFmpeg errors?**
- Test RTSP: `ffprobe rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main`
- Check NVR is reachable: `ping hwmnbn.myddns.me`

## RTSP URLs for Reolink Cameras

```
Camera 1: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main
Camera 2: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_02_main
Camera 3: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_03_main
Camera 4: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_04_main
Camera 5: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_05_main
Camera 6: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_06_main
Camera 7: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_07_main
```

## Next Steps

- See `DEPLOYMENT.md` for detailed deployment guide
- See `README.md` for complete documentation
- Configure custom domain (optional)
- Set up Cloudflare Access for authentication (optional)

---

**Need Help?**
- Cloudflare Stream Docs: https://developers.cloudflare.com/stream/
- Cloudflare Discord: https://discord.gg/cloudflaredev
