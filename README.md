# Reolink NVR Cloudflare Stream Proxy

Stream your Reolink NVR camera feeds online using Cloudflare Workers and Cloudflare Stream API.

## Features

- 🎥 Stream 7 Reolink camera feeds simultaneously
- 🔒 Server-side authentication (no login page needed)
- ⚡ Powered by Cloudflare Workers and Stream API
- 📱 Responsive design for desktop and mobile
- 🎬 Automatic stream recording with DVR capabilities
- 🚀 Global CDN delivery via Cloudflare's network

## Project Structure

```
/home/marswc/code/stream/
├── src/
│   ├── index.ts           # Worker backend with Stream API integration
│   └── public/
│       └── index.html     # Frontend with video players
├── wrangler.jsonc         # Cloudflare Workers configuration
├── package.json           # Node.js dependencies
└── README.md             # This file
```

## Prerequisites

- Cloudflare account with Stream enabled
- Reolink NVR accessible at: `hwmnbn.myddns.me:8080`
- Node.js 18+ and npm installed
- FFmpeg (for stream forwarding)

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Create Cloudflare Stream API Token

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Select "Create Custom Token"
4. Add permissions:
   - **Stream**: Edit
5. Copy the token for the next step

### 3. Configure Secrets

Set up the required secrets using Wrangler:

```bash
# NVR Password
npx wrangler secret put NVR_PASSWORD
# Enter: @codecam22

# Cloudflare API Token (from step 2)
npx wrangler secret put CLOUDFLARE_API_TOKEN
# Paste the API token you created

# Cloudflare Account ID
npx wrangler secret put CLOUDFLARE_ACCOUNT_ID
# Find this at: https://dash.cloudflare.com/ (right sidebar)
```

### 4. Create KV Namespace

Create the Workers KV namespace for caching stream metadata:

```bash
# Create production namespace
npx wrangler kv:namespace create STREAM_CACHE

# Create preview namespace for local development
npx wrangler kv:namespace create STREAM_CACHE --preview
```

**Update `wrangler.jsonc`** with the IDs returned:

```jsonc
"kv_namespaces": [
  {
    "binding": "STREAM_CACHE",
    "id": "<PRODUCTION_ID>",
    "preview_id": "<PREVIEW_ID>"
  }
]
```

### 5. Deploy the Worker

```bash
# Deploy to Cloudflare
npx wrangler deploy

# Or run locally for testing
npx wrangler dev
```

### 6. Initialize Stream Inputs

1. Open your deployed Worker URL in a browser
2. Click **"Initialize Streams"** button
3. This creates 7 Cloudflare Stream Live inputs
4. Copy the RTMP ingest URLs displayed for each camera

### 7. Configure Stream Forwarding

You need to forward RTSP streams from your Reolink NVR to Cloudflare Stream.

#### Option A: Using FFmpeg (Recommended)

Install FFmpeg and run these commands (one for each camera):

```bash
# Camera 1
ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main \
  -c:v copy -c:a copy -f flv \
  <RTMP_INGEST_URL_FROM_STEP_6>

# Camera 2
ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_02_main \
  -c:v copy -c:a copy -f flv \
  <RTMP_INGEST_URL_FROM_STEP_6>

# Repeat for cameras 3-7 (change _01_, _02_, etc.)
```

**Run as background services** using systemd, supervisor, or screen/tmux.

#### Option B: Using Docker Compose

Create a `docker-compose.yml`:

```yaml
version: '3'
services:
  camera1:
    image: jrottenberg/ffmpeg:latest
    restart: unless-stopped
    command: >
      -rtsp_transport tcp
      -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main
      -c:v copy -c:a copy -f flv
      <RTMP_INGEST_URL>

  camera2:
    image: jrottenberg/ffmpeg:latest
    restart: unless-stopped
    command: >
      -rtsp_transport tcp
      -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_02_main
      -c:v copy -c:a copy -f flv
      <RTMP_INGEST_URL>

  # Add camera3-camera7 similarly
```

Then run:
```bash
docker-compose up -d
```

## Usage

Once deployed and streaming:

1. Visit your Worker URL (e.g., `https://reolink-stream-proxy.yourname.workers.dev`)
2. All 7 camera streams will load automatically
3. No login required - authentication happens server-side
4. Click any stream to view full screen

## API Endpoints

- `GET /` - Main webpage with video players
- `GET /api/streams/init` - Initialize all Stream Live inputs
- `GET /api/streams/list` - List configured streams
- `GET /api/streams/refresh` - Refresh stream configuration
- `GET /api/camera/{id}` - Proxy camera snapshot requests

## Architecture

### How It Works

```
Reolink NVR (RTSP)
    ↓
FFmpeg (converts RTSP → RTMPS)
    ↓
Cloudflare Stream (ingestion & transcoding)
    ↓
Cloudflare Workers (serves webpage)
    ↓
User's Browser (HLS/DASH playback)
```

### Key Components

1. **Cloudflare Worker**:
   - Authenticates to Reolink NVR
   - Creates/manages Stream Live inputs
   - Serves the frontend webpage
   - Caches stream metadata in KV

2. **Cloudflare Stream**:
   - Ingests RTMPS streams
   - Transcodes to multiple bitrates (ABR)
   - Delivers via HLS/DASH
   - Records streams automatically

3. **Frontend**:
   - Responsive grid layout
   - Cloudflare Stream Player integration
   - Real-time status updates

## Troubleshooting

### Streams not appearing?

1. Check FFmpeg is running and connected:
   ```bash
   ps aux | grep ffmpeg
   ```

2. Verify RTSP URLs work:
   ```bash
   ffprobe rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main
   ```

3. Check Cloudflare Stream dashboard:
   - https://dash.cloudflare.com/?to=/:account/stream/inputs
   - Verify inputs show "Live" status

### Worker errors?

Check logs:
```bash
npx wrangler tail
```

### KV namespace issues?

List namespaces:
```bash
npx wrangler kv:namespace list
```

## Configuration

### Camera Names

Edit camera names in `src/index.ts`:

```typescript
const CAMERA_NAMES = [
  'Camera 1 - Front Entrance',
  'Camera 2 - Backyard',
  // ... customize as needed
];
```

### Recording Settings

Modify recording behavior in `src/index.ts`:

```typescript
recording: {
  mode: 'automatic',        // or 'off'
  timeoutSeconds: 10,       // seconds before ending recording
  requireSignedURLs: false, // set true for private streams
}
```

## Costs

- **Cloudflare Workers**: Free tier (100,000 requests/day)
- **Cloudflare Stream**:
  - $5/month per 1,000 minutes of video stored
  - $1 per 1,000 minutes of video delivered
  - Live streaming included in pricing

## Security Considerations

- ✅ NVR credentials stored as Worker secrets (encrypted)
- ✅ No credentials exposed to frontend
- ✅ CORS headers configured
- ⚠️ Consider enabling `requireSignedURLs` for private streams
- ⚠️ Set up Cloudflare Access for additional protection

## License

MIT

## Support

For issues or questions:
- Cloudflare Stream Docs: https://developers.cloudflare.com/stream/
- Cloudflare Workers Docs: https://developers.cloudflare.com/workers/
- Reolink API Docs: https://support.reolink.com/hc/en-us/articles/360007010473-API-Reference
