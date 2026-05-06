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
// Backward-compat fallback for projects still on the legacy key.
if (!SECRET_KEY) {
  SECRET_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
}
const BUCKET = 'backups';

const corsHeaders: HeadersInit = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }
  if (!SUPABASE_URL || !SECRET_KEY) {
    return jsonResponse({ error: 'Server not configured' }, 500);
  }

  const auth = req.headers.get('Authorization');
  if (!auth) {
    return jsonResponse({ error: 'Missing Authorization header' }, 401);
  }

  // 1. Identify the user via their JWT.
  const userClient = createClient(SUPABASE_URL, SECRET_KEY, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) {
    return jsonResponse({ error: 'Invalid session' }, 401);
  }
  const user = userData.user;
  if (user.is_anonymous) {
    return jsonResponse({ error: 'Cannot delete anonymous session' }, 403);
  }
  const uid = user.id;

  // 2. Admin client for privileged operations.
  const admin = createClient(SUPABASE_URL, SECRET_KEY, {
    auth: { persistSession: false },
  });

  // 3. List + remove all Storage objects under {uid}/.
  const { data: files, error: listErr } = await admin.storage.from(BUCKET).list(uid);
  if (listErr) {
    return jsonResponse({ error: `Storage list failed: ${listErr.message}` }, 500);
  }
  if (files && files.length > 0) {
    const paths = files.map((f) => `${uid}/${f.name}`);
    const { error: removeErr } = await admin.storage.from(BUCKET).remove(paths);
    if (removeErr) {
      return jsonResponse({ error: `Storage remove failed: ${removeErr.message}` }, 500);
    }
  }

  // 4. Delete the index row in the `backups` table (best-effort — table may not exist in all envs).
  await admin.from('backups').delete().eq('user_id', uid).then(() => {}, () => {});

  // 5. Delete the Auth identity.
  const { error: delErr } = await admin.auth.admin.deleteUser(uid);
  if (delErr) {
    return jsonResponse({ error: `Auth delete failed: ${delErr.message}` }, 500);
  }

  return jsonResponse({ ok: true });
});
