// supabase/functions/version-check/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SECRET_KEYS_RAW = Deno.env.get('SUPABASE_SECRET_KEYS');

let SECRET_KEY: string | undefined;
if (SECRET_KEYS_RAW) {
  try {
    const parsed = JSON.parse(SECRET_KEYS_RAW) as Record<string, string>;
    SECRET_KEY = parsed['default'];
  } catch {
    SECRET_KEY = undefined;
  }
}
if (!SECRET_KEY) {
  SECRET_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
}

const corsHeaders: HeadersInit = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
};

function jsonResponse(body: unknown, status = 200, extraHeaders: HeadersInit = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      ...extraHeaders,
    },
  });
}

const ALLOWED_PLATFORMS = new Set(['ios', 'android']);

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== 'GET') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }
  if (!SUPABASE_URL || !SECRET_KEY) {
    return jsonResponse({ error: 'Server not configured' }, 500);
  }

  const url = new URL(req.url);
  const platform = url.searchParams.get('platform');
  if (!platform) {
    return jsonResponse({ error: 'Missing platform query param' }, 400);
  }
  if (!ALLOWED_PLATFORMS.has(platform)) {
    return jsonResponse({ error: 'Invalid platform' }, 400);
  }

  const admin = createClient(SUPABASE_URL, SECRET_KEY, {
    auth: { persistSession: false },
  });

  const { data, error } = await admin
    .from('app_versions')
    .select('platform, latest_version, min_supported_version, security_flag, release_notes_fr, store_url')
    .eq('platform', platform)
    .maybeSingle();

  if (error) {
    return jsonResponse({ error: `Lookup failed: ${error.message}` }, 500);
  }
  if (!data) {
    return jsonResponse({ error: 'Platform not configured' }, 404);
  }

  return jsonResponse(
    {
      platform: data.platform,
      latestVersion: data.latest_version,
      minSupportedVersion: data.min_supported_version,
      securityFlag: data.security_flag,
      releaseNotesFr: data.release_notes_fr,
      storeUrl: data.store_url,
    },
    200,
    { 'Cache-Control': 'public, max-age=300' },
  );
});
