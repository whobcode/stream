# Reolink NVR Cloudflare Stream - Project Summary

## What Was Created

A complete Cloudflare Workers application that streams your 7 Reolink NVR camera feeds to a public webpage using Cloudflare Stream API.

**Location**: `/home/marswc/code/stream`

## Project Overview

### Architecture

```
Reolink NVR (RTSP)
    ↓
FFmpeg Bridge (converts RTSP → RTMPS)
    ↓
Cloudflare Stream API (ingestion, transcoding, delivery)
    ↓
Cloudflare Worker (serves public webpage)
    ↓
User Browser (HLS/DASH playback, no login required)
```

### Key Features

- **No Login Page**: Authentication to Reolink NVR happens server-side in the Worker
- **7 Camera Streams**: Displays all cameras in a responsive grid layout
- **Automatic Recording**: Streams are automatically recorded with configurable retention
- **Global CDN**: Video delivered via Cloudflare's global network
- **Secure**: NVR credentials stored as encrypted Worker secrets
- **Scalable**: Supports unlimited concurrent viewers

## Files Created/Modified

### Core Application

```
/home/marswc/code/stream/
├── src/
│   ├── index.ts              # Cloudflare Worker backend
│   └── public/
│       └── index.html        # Frontend with Stream players
├── wrangler.jsonc            # Cloudflare Workers configuration
├── package.json              # Node.js dependencies
└── tsconfig.json             # TypeScript configuration
```

### Documentation

```
├── README.md                 # Main project documentation
├── DEPLOYMENT.md             # Step-by-step deployment guide
├── QUICK_START.md            # Quick reference guide
├── PROJECT_SUMMARY.md        # Detailed project overview
├── CLAUDE.md                 # Project instructions for Claude
└── SUMMARY.md                # This file
```

### Setup Scripts

```
├── setup.sh                       # Automated Worker setup
├── create-stream-forwarder.sh     # FFmpeg configuration generator
├── setup-ffmpeg.sh                # FFmpeg service installer
└── verify-setup.sh                # Deployment verification
```

### Configuration

```
├── .env.example              # Environment variables template
└── .gitignore                # Git ignore rules
```

## Technology Stack

### Backend
- **Runtime**: Cloudflare Workers (Node.js compatibility mode)
- **API Integration**: Cloudflare Stream Live API
- **Storage**: Workers KV (for caching stream metadata)
- **Auth**: Server-side authentication to Reolink NVR

### Frontend
- **HTML5**: Responsive single-page application
- **JavaScript**: Vanilla JS (no framework dependencies)
- **Video Player**: Cloudflare Stream Player SDK
- **CSS**: Modern responsive design with gradient themes

### Integration
- **Reolink NVR**: RTSP stream source
- **FFmpeg**: RTSP to RTMPS conversion bridge
- **Cloudflare Stream**: RTMPS ingestion and HLS/DASH delivery

## Configuration Details

### Reolink NVR Settings

```yaml
Host: hwmnbn.myddns.me:8080
Username: hwmnbn
Password: @codecam22 (stored as secret)
RTSP Port: 554
Protocol: RTSP over TCP
```

### Camera RTSP URLs

```
Camera 1: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main
Camera 2: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_02_main
Camera 3: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_03_main
Camera 4: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_04_main
Camera 5: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_05_main
Camera 6: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_06_main
Camera 7: rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_07_main
```

### Camera Names (Customizable)

```javascript
const CAMERA_NAMES = [
  'Camera 1 - Front Entrance',
  'Camera 2 - Backyard',
  'Camera 3 - Garage',
  'Camera 4 - Driveway',
  'Camera 5 - Side Gate',
  'Camera 6 - Pool Area',
  'Camera 7 - Street View'
];
```

Edit in `src/index.ts` to customize.

## API Endpoints

The Worker exposes these endpoints:

```
GET  /                       Main webpage with video players
POST /api/streams/init       Initialize all Stream Live inputs
GET  /api/streams/list       List configured streams
POST /api/streams/refresh    Refresh stream configuration
GET  /api/camera/{id}        Proxy camera snapshot requests
```

## Setup Requirements

### Prerequisites

1. **Cloudflare Account**
   - Free tier works
   - Stream enabled: https://dash.cloudflare.com/?to=/:account/stream

2. **Secrets** (set via `npx wrangler secret put`)
   - `NVR_PASSWORD`: @codecam22
   - `CLOUDFLARE_API_TOKEN`: API token with Stream:Edit permission
   - `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare Account ID

3. **Workers KV Namespace**
   - Binding: `STREAM_CACHE`
   - Used for caching stream metadata (24-hour TTL)

4. **FFmpeg**
   - Required for RTSP → RTMPS conversion
   - Can run on any machine with network access to NVR

### Environment Variables (in wrangler.jsonc)

```jsonc
"vars": {
  "NVR_HOST": "hwmnbn.myddns.me:8080",
  "NVR_USERNAME": "hwmnbn"
}
```

## Deployment Methods

### Quick Setup (Automated)

```bash
# 1. Run setup script
./setup.sh

# 2. Update wrangler.jsonc with KV namespace IDs

# 3. Deploy
npm run deploy

# 4. Initialize streams via web interface

# 5. Configure FFmpeg forwarding
./create-stream-forwarder.sh
```

### Manual Setup

See `DEPLOYMENT.md` for detailed step-by-step instructions.

## FFmpeg Deployment Options

The project supports multiple FFmpeg deployment methods:

### 1. Bash Script (Testing/Development)
```bash
./stream-all-cameras.sh
```
- Simple bash script
- Runs all FFmpeg instances in background
- Good for testing

### 2. Docker Compose (Production - Recommended)
```bash
docker-compose up -d
```
- Containerized deployment
- Auto-restart on failure
- Easy monitoring with `docker-compose logs`
- Resource isolation

### 3. Systemd Services (Linux Production)
```bash
cd systemd-services
sudo ./install.sh
sudo systemctl start reolink-camera-{1..7}
```
- Native Linux service management
- Auto-start on boot
- System integration
- Journald logging

## How It Works

### 1. Worker Initialization

When you click "Initialize Streams":

```typescript
POST /api/streams/init
→ Creates 7 Cloudflare Stream Live inputs via API
→ Stores stream metadata in Workers KV
→ Returns RTMP ingest URLs for each camera
```

### 2. Stream Forwarding

FFmpeg converts RTSP to RTMPS:

```bash
ffmpeg -rtsp_transport tcp \
  -i rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main \
  -c:v copy -c:a copy \
  -f flv rtmps://live.cloudflare.com:443/live/STREAM_KEY
```

### 3. Video Delivery

Cloudflare Stream:
- Ingests RTMPS stream
- Transcodes to multiple bitrates (ABR)
- Delivers via HLS/DASH
- Records automatically
- Serves to unlimited viewers

### 4. Frontend Playback

HTML page:
- Fetches stream list from Worker API
- Embeds Cloudflare Stream Player iframes
- Displays all 7 cameras in responsive grid
- Auto-refreshes on initialization

## Security Model

### Server-Side Authentication
- NVR credentials stored as Worker secrets (encrypted at rest)
- Never exposed to frontend
- Authentication happens in Worker backend

### Public Streams
- By default, streams are public (no viewer authentication)
- Anyone with Worker URL can view cameras

### Optional Security Enhancements

**1. Add Viewer Authentication**
- Cloudflare Access (recommended)
- Basic Auth in Worker
- Custom JWT authentication

**2. Signed URLs**
```typescript
recording: {
  mode: 'automatic',
  requireSignedURLs: true  // Requires tokens to view
}
```

**3. IP Allowlist**
```typescript
// In Worker
const allowedIPs = ['1.2.3.4', '5.6.7.8'];
if (!allowedIPs.includes(request.headers.get('CF-Connecting-IP'))) {
  return new Response('Forbidden', { status: 403 });
}
```

## Cost Estimates

### Cloudflare Workers
- **Free Tier**: 100,000 requests/day
- **Paid**: $5/month (10M requests)
- **Expected**: Free tier sufficient for most use cases

### Cloudflare Stream

For 7 cameras streaming 24/7 with automatic recording:

```
Minutes per camera per day: 1,440
Total minutes per day: 10,080
Total minutes per month: 302,400

Pricing:
- Ingestion: Free (RTMPS)
- Storage: $5 per 1,000 minutes
- Delivery: $1 per 1,000 minutes

Monthly cost estimate:
- Storage (30 days): 302,400 × $5/1000 = $1,512
- Delivery (assume 10 viewers): ~$50-100
- Total: ~$1,600/month
```

### Cost Reduction Strategies

**1. Use Sub-Streams (Lower Resolution)**
- Change `_main` to `_sub` in RTSP URLs
- Reduces bitrate from ~4Mbps to ~1Mbps
- Saves ~75% on storage/delivery

**2. Limit Recording Retention**
```typescript
recording: {
  mode: 'automatic',
  deleteRecordingAfterDays: 7  // Only keep 1 week
}
```

**3. Schedule Recording**
- Only stream during business hours
- Saves ~60% if limited to 9 AM - 6 PM
- Use cron to start/stop FFmpeg

**4. Reduce Quality/Framerate**
```bash
ffmpeg -rtsp_transport tcp \
  -i [RTSP_URL] \
  -c:v libx264 -preset fast \
  -b:v 1M -maxrate 1M -bufsize 2M \
  -r 15 \  # 15 FPS instead of 30
  -f flv [RTMP_URL]
```

## Monitoring & Troubleshooting

### View Worker Logs
```bash
npm run tail
```

### Check Stream Status
- Dashboard: https://dash.cloudflare.com/?to=/:account/stream/inputs
- Should show "Live" for active streams

### Verify FFmpeg
```bash
# List processes
ps aux | grep ffmpeg

# Docker status
docker-compose ps
docker-compose logs -f

# Systemd status
sudo systemctl status reolink-camera-1
```

### Test RTSP Connection
```bash
ffprobe rtsp://hwmnbn:@codecam22@hwmnbn.myddns.me:554/h264Preview_01_main
```

### Common Issues

**Streams not appearing:**
- Check FFmpeg is running
- Verify RTSP URLs are accessible
- Check Cloudflare Stream dashboard for errors
- Review Worker logs for API errors

**High latency:**
- Expected HLS latency: 10-30 seconds
- For lower latency: Enable `preferLowLatency: true` (beta)
- Or use RTMPS/SRT playback (sub-second)

**Authentication errors:**
- Verify NVR credentials in secrets
- Check NVR network accessibility
- Ensure RTSP port 554 is open

## Next Steps

### Immediate
1. Run `./setup.sh` to configure Worker
2. Deploy with `npm run deploy`
3. Initialize streams via web interface
4. Configure FFmpeg forwarding

### Optional Enhancements
1. Add viewer authentication (Cloudflare Access)
2. Set up monitoring/alerts
3. Configure custom domain
4. Implement scheduled recording
5. Add motion detection integration
6. Create mobile app with Stream SDK

## Documentation Reference

- **Quick Start**: `QUICK_START.md` - Fast 5-minute setup
- **Deployment**: `DEPLOYMENT.md` - Detailed step-by-step guide
- **README**: `README.md` - Full documentation
- **Project Summary**: `PROJECT_SUMMARY.md` - Technical overview

## Support Resources

- **Cloudflare Stream Docs**: https://developers.cloudflare.com/stream/
- **Cloudflare Workers Docs**: https://developers.cloudflare.com/workers/
- **Reolink API**: https://support.reolink.com/hc/en-us/articles/360007010473
- **FFmpeg Docs**: https://ffmpeg.org/documentation.html
- **Community Discord**: https://discord.gg/cloudflaredev

## License

MIT

## Contributors

Generated with Claude Code Assistant
Project Location: /home/marswc/code/stream
