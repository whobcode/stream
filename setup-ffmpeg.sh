#!/bin/bash

# FFmpeg Stream Forwarding Setup Script
# This script helps configure FFmpeg to forward RTSP streams from Reolink NVR to Cloudflare Stream

set -e

echo "==================================="
echo "Reolink → Cloudflare Stream Setup"
echo "==================================="
echo ""

# Check if FFmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ FFmpeg is not installed!"
    echo ""
    echo "Install FFmpeg:"
    echo "  - Ubuntu/Debian: sudo apt-get install ffmpeg"
    echo "  - macOS: brew install ffmpeg"
    echo "  - Windows: Download from https://ffmpeg.org/download.html"
    echo ""
    exit 1
fi

echo "✓ FFmpeg is installed: $(ffmpeg -version | head -n1)"
echo ""

# NVR Configuration
NVR_HOST="hwmnbn.myddns.me:8080"
NVR_USER="hwmnbn"
NVR_PASS="@codecam22"
RTSP_PORT="554"

echo "NVR Configuration:"
echo "  Host: $NVR_HOST"
echo "  User: $NVR_USER"
echo "  RTSP Port: $RTSP_PORT"
echo ""

# Check if RTMP URLs are provided
if [ $# -eq 0 ]; then
    echo "⚠️  No RTMP ingest URLs provided!"
    echo ""
    echo "Usage:"
    echo "  ./setup-ffmpeg.sh <rtmp_url_1> <rtmp_url_2> ... <rtmp_url_7>"
    echo ""
    echo "Steps:"
    echo "  1. Deploy the Worker: npx wrangler deploy"
    echo "  2. Visit the Worker URL and click 'Initialize Streams'"
    echo "  3. Copy the 7 RTMP ingest URLs"
    echo "  4. Run this script with the URLs as arguments"
    echo ""
    echo "Example:"
    echo "  ./setup-ffmpeg.sh \\"
    echo "    'rtmps://live.cloudflare.com:443/live/KEY1' \\"
    echo "    'rtmps://live.cloudflare.com:443/live/KEY2' \\"
    echo "    ..."
    echo ""
    exit 1
fi

# Number of cameras
NUM_CAMERAS=$#
echo "Starting stream forwarding for $NUM_CAMERAS cameras..."
echo ""

# Create systemd service files (Linux only)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Creating systemd service files..."
    SYSTEMD_DIR="$HOME/.config/systemd/user"
    mkdir -p "$SYSTEMD_DIR"

    for i in $(seq 1 $NUM_CAMERAS); do
        RTMP_URL="${!i}"
        CAMERA_ID=$(printf "%02d" $i)
        SERVICE_FILE="$SYSTEMD_DIR/reolink-camera-$i.service"

        cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Reolink Camera $i Stream Forwarder
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=10
ExecStart=/usr/bin/ffmpeg \\
    -rtsp_transport tcp \\
    -i rtsp://$NVR_USER:$NVR_PASS@${NVR_HOST%:*}:$RTSP_PORT/h264Preview_${CAMERA_ID}_main \\
    -c:v copy \\
    -c:a copy \\
    -f flv \\
    "$RTMP_URL"

[Install]
WantedBy=default.target
EOF

        echo "  ✓ Created: $SERVICE_FILE"
    done

    echo ""
    echo "To enable and start services:"
    echo "  systemctl --user daemon-reload"
    for i in $(seq 1 $NUM_CAMERAS); do
        echo "  systemctl --user enable reolink-camera-$i.service"
        echo "  systemctl --user start reolink-camera-$i.service"
    done
    echo ""
    echo "To view logs:"
    echo "  journalctl --user -u reolink-camera-1.service -f"
    echo ""

else
    # For macOS or other systems, create shell scripts
    echo "Creating FFmpeg launch scripts..."

    for i in $(seq 1 $NUM_CAMERAS); do
        RTMP_URL="${!i}"
        CAMERA_ID=$(printf "%02d" $i)
        SCRIPT_FILE="start-camera-$i.sh"

        cat > "$SCRIPT_FILE" << EOF
#!/bin/bash
# Stream forwarder for Camera $i

echo "Starting Camera $i stream forwarding..."
echo "RTSP: rtsp://$NVR_USER:***@${NVR_HOST%:*}:$RTSP_PORT/h264Preview_${CAMERA_ID}_main"
echo "RTMP: $RTMP_URL"
echo ""

while true; do
    ffmpeg \\
        -rtsp_transport tcp \\
        -i "rtsp://$NVR_USER:$NVR_PASS@${NVR_HOST%:*}:$RTSP_PORT/h264Preview_${CAMERA_ID}_main" \\
        -c:v copy \\
        -c:a copy \\
        -f flv \\
        "$RTMP_URL"

    echo "Stream disconnected. Reconnecting in 5 seconds..."
    sleep 5
done
EOF

        chmod +x "$SCRIPT_FILE"
        echo "  ✓ Created: $SCRIPT_FILE"
    done

    echo ""
    echo "To start streaming, run in separate terminals:"
    for i in $(seq 1 $NUM_CAMERAS); do
        echo "  ./$SCRIPT_FILE"
    done
    echo ""
    echo "Or run all in background using screen/tmux"
    echo ""
fi

# Create Docker Compose file
echo "Creating docker-compose.yml..."
cat > docker-compose.yml << 'COMPOSE_START'
version: '3.8'
services:
COMPOSE_START

for i in $(seq 1 $NUM_CAMERAS); do
    RTMP_URL="${!i}"
    CAMERA_ID=$(printf "%02d" $i)

    cat >> docker-compose.yml << EOF
  camera$i:
    image: jrottenberg/ffmpeg:latest
    container_name: reolink-camera-$i
    restart: unless-stopped
    command:
      - -rtsp_transport
      - tcp
      - -i
      - rtsp://$NVR_USER:$NVR_PASS@${NVR_HOST%:*}:$RTSP_PORT/h264Preview_${CAMERA_ID}_main
      - -c:v
      - copy
      - -c:a
      - copy
      - -f
      - flv
      - "$RTMP_URL"

EOF
done

echo "  ✓ Created: docker-compose.yml"
echo ""
echo "To start with Docker:"
echo "  docker-compose up -d"
echo ""
echo "To view Docker logs:"
echo "  docker-compose logs -f camera1"
echo ""

echo "==================================="
echo "✓ Setup Complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo "  1. Choose your preferred method (systemd, shell scripts, or Docker)"
echo "  2. Start the stream forwarders"
echo "  3. Visit your Worker URL to view live streams"
echo ""
