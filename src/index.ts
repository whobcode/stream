/**
 * Reolink NVR Stream Proxy Worker
 *
 * This Worker:
 * 1. Authenticates to Reolink NVR server-side
 * 2. Creates/manages Cloudflare Stream Live inputs for each camera
 * 3. Provides RTMP/RTSP URLs for ingestion
 * 4. Serves a public webpage with all camera streams
 */

interface Env {
  ASSETS: Fetcher;
  STREAM_CACHE: KVNamespace;
  NVR_HOST: string;
  NVR_USERNAME: string;
  NVR_PASSWORD: string;
  CLOUDFLARE_ACCOUNT_ID: string;
  CLOUDFLARE_API_TOKEN: string;
}

interface StreamLiveInput {
  uid: string;
  rtmps: {
    url: string;
    streamKey: string;
  };
  rtmpsPlayback: {
    url: string;
  };
  webRTC?: {
    url: string;
  };
  status?: {
    state: string;
  };
}

interface CameraStream {
  id: string;
  name: string;
  streamUid: string;
  playbackUrl: string;
  rtmpIngestUrl: string;
}

const CAMERA_NAMES = [
  'Camera 1 - Front Entrance',
  'Camera 2 - Backyard',
  'Camera 3 - Garage',
  'Camera 4 - Driveway',
  'Camera 5 - Side Gate',
  'Camera 6 - Pool Area',
  'Camera 7 - Street View'
];

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS headers for API endpoints
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // API Routes
    if (path === '/api/streams/init') {
      return handleInitStreams(env, corsHeaders);
    }

    if (path === '/api/streams/list') {
      return handleListStreams(env, corsHeaders);
    }

    if (path === '/api/streams/refresh') {
      return handleRefreshStreams(env, corsHeaders);
    }

    if (path.startsWith('/api/camera/')) {
      const cameraId = path.split('/')[3];
      return handleCameraProxy(cameraId, env, corsHeaders);
    }

    // Serve static assets (HTML page)
    return env.ASSETS.fetch(request);
  },
};

/**
 * Initialize all Stream Live inputs for cameras
 */
async function handleInitStreams(env: Env, corsHeaders: Record<string, string>): Promise<Response> {
  try {
    const streams: CameraStream[] = [];

    // Check if streams already exist in KV
    const cachedStreams = await env.STREAM_CACHE.get('camera_streams', 'json');
    if (cachedStreams) {
      return Response.json({
        success: true,
        streams: cachedStreams,
        message: 'Using cached stream configuration'
      }, { headers: corsHeaders });
    }

    // Create Stream Live inputs for each camera
    for (let i = 0; i < CAMERA_NAMES.length; i++) {
      const cameraId = `camera-${i + 1}`;
      const cameraName = CAMERA_NAMES[i];

      console.log(`Creating Stream Live input for ${cameraName}...`);

      const streamInput = await createStreamLiveInput(env, cameraName);

      if (streamInput) {
        streams.push({
          id: cameraId,
          name: cameraName,
          streamUid: streamInput.uid,
          playbackUrl: streamInput.rtmpsPlayback.url,
          rtmpIngestUrl: `${streamInput.rtmps.url}/${streamInput.rtmps.streamKey}`
        });
      }
    }

    // Cache the stream configuration in KV (24 hour TTL)
    await env.STREAM_CACHE.put('camera_streams', JSON.stringify(streams), {
      expirationTtl: 86400
    });

    return Response.json({
      success: true,
      streams,
      message: `Created ${streams.length} Stream Live inputs`
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('Error initializing streams:', error);
    return Response.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, {
      status: 500,
      headers: corsHeaders
    });
  }
}

/**
 * List all configured camera streams
 */
async function handleListStreams(env: Env, corsHeaders: Record<string, string>): Promise<Response> {
  try {
    const streams = await env.STREAM_CACHE.get('camera_streams', 'json');

    if (!streams) {
      return Response.json({
        success: false,
        error: 'No streams configured. Call /api/streams/init first.'
      }, {
        status: 404,
        headers: corsHeaders
      });
    }

    return Response.json({
      success: true,
      streams
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('Error listing streams:', error);
    return Response.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, {
      status: 500,
      headers: corsHeaders
    });
  }
}

/**
 * Refresh stream status and configuration
 */
async function handleRefreshStreams(env: Env, corsHeaders: Record<string, string>): Promise<Response> {
  try {
    // Clear cache and reinitialize
    await env.STREAM_CACHE.delete('camera_streams');
    return handleInitStreams(env, corsHeaders);

  } catch (error) {
    console.error('Error refreshing streams:', error);
    return Response.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, {
      status: 500,
      headers: corsHeaders
    });
  }
}

/**
 * Proxy requests to Reolink NVR (for camera snapshots, etc.)
 */
async function handleCameraProxy(
  cameraId: string,
  env: Env,
  corsHeaders: Record<string, string>
): Promise<Response> {
  try {
    // Authenticate to Reolink NVR and get camera snapshot
    const nvr_url = `http://${env.NVR_HOST}/cgi-bin/api.cgi`;

    const authPayload = [{
      cmd: 'Login',
      action: 0,
      param: {
        User: {
          userName: env.NVR_USERNAME,
          password: env.NVR_PASSWORD
        }
      }
    }];

    const authResponse = await fetch(nvr_url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(authPayload)
    });

    if (!authResponse.ok) {
      throw new Error('Failed to authenticate to NVR');
    }

    const authData = await authResponse.json() as any;
    const token = authData[0]?.value?.Token?.name;

    if (!token) {
      throw new Error('No authentication token received');
    }

    // Get camera snapshot
    const channelId = parseInt(cameraId.replace('camera-', '')) - 1;
    const snapshotUrl = `http://${env.NVR_HOST}/cgi-bin/api.cgi?cmd=Snap&channel=${channelId}&token=${token}`;

    const snapshotResponse = await fetch(snapshotUrl);

    if (!snapshotResponse.ok) {
      throw new Error('Failed to get camera snapshot');
    }

    return new Response(snapshotResponse.body, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'image/jpeg',
        'Cache-Control': 'public, max-age=5'
      }
    });

  } catch (error) {
    console.error('Error proxying camera request:', error);
    return Response.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, {
      status: 500,
      headers: corsHeaders
    });
  }
}

/**
 * Create a Cloudflare Stream Live input
 */
async function createStreamLiveInput(env: Env, name: string): Promise<StreamLiveInput | null> {
  try {
    const response = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${env.CLOUDFLARE_ACCOUNT_ID}/stream/live_inputs`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${env.CLOUDFLARE_API_TOKEN}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          meta: {
            name: name
          },
          recording: {
            mode: 'automatic',
            timeoutSeconds: 10
          }
        })
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Failed to create Stream Live input: ${response.status} - ${errorText}`);
      return null;
    }

    const data = await response.json() as any;
    return data.result;

  } catch (error) {
    console.error('Error creating Stream Live input:', error);
    return null;
  }
}
