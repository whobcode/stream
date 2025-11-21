- PROJECT: Cloudflare Stream + Reolink NVR Camera Setup

  GOAL: Create a Node.js/Wrangler-based Cloudflare Workers application to stream Reolink NVR home camera setup online with multiple webpages.

  COMPLETED:
  - Created /home/marswc/code/stream directory
  - Initialized npm project with package.json
  - Installed wrangler@4.49.0

  TECH STACK:
  - Runtime: Cloudflare Workers (Node.js)
  - Build tool: Wrangler@4.49.0
  - API: Cloudflare Stream API
  - Camera source: Reolink NVR
  - Config: wrangler.jsonc
  - Entry point: src/index.js

  CLOUDFLARE STREAM DOCUMENTATION REFERENCES:
  - https://developers.cloudflare.com/stream/changelog/index.md
  - https://developers.cloudflare.com/stream/faq/index.md
  - https://developers.cloudflare.com/stream/index.md
  - https://developers.cloudflare.com/stream/get-started/index.md
  - https://developers.cloudflare.com/stream/stream-api/index.md
  - https://developers.cloudflare.com/stream/stream-live/stream-live-api/index.md
  - https://developers.cloudflare.com/stream/stream-live/start-stream-live/index.md
  - https://developers.cloudflare.com/stream/stream-live/watch-live-stream/index.md
  - https://developers.cloudflare.com/stream/stream-live/webhooks/index.md
  - https://developers.cloudflare.com/stream/viewing-videos/using-the-stream-player/using-the-player-api/index.md
  - https://developers.cloudflare.com/stream/viewing-videos/using-the-stream-player/index.md
  - https://developers.cloudflare.com/stream/manage-video-library/index.md
  - https://developers.cloudflare.com/stream/manage-video-library/using-webhooks/index.md
  - https://developers.cloudflare.com/stream/getting-analytics/fetching-bulk-analytics/index.md
  - https://developers.cloudflare.com/stream/getting-analytics/index.md

  KEY CLOUDFLARE STREAM FEATURES:
  - Live streaming via RTMPS protocol
  - HLS/DASH playback support
  - Stream Player integration
  - Adaptive Bitrate Streaming (ABR)
  - Direct creator uploads
  - Webhooks for events
  - GraphQL Analytics API
  - DVR for Live
  - Recording/replay of live streams

  TODO (in order):
  1. Create wrangler.jsonc configuration
  2. Set up project structure (src/, public/, config files)
  3. Create Worker backend (src/index.js) for Stream API integration
  4. Build frontend with video playback pages
  5. Create Reolink camera integration module
  6. Set up authentication and security

  REOLINK INTEGRATION APPROACH:
  - Convert Reolink RTSP/RTMP stream to Cloudflare Stream RTMPS input
  - Use Stream Live API to create live input and get ingest URL
  - Configure Reolink to push stream to Cloudflare

  NEXT STEP: Create wrangler.jsonc and src/index.js project structure

  ---