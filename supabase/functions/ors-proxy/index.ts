// supabase/functions/ors-proxy/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const ORS_BASE = 'https://api.openrouteservice.org';
const ORS_API_KEY = Deno.env.get('ORS_API_KEY');

serve(async (req: Request) => {
  // CORS preflight (le SDK supabase-flutter envoie un OPTIONS d'abord)
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  if (!ORS_API_KEY) {
    return new Response('ORS_API_KEY not configured', { status: 500 });
  }

  // Le path après /ors-proxy/ — ex. "v2/directions/driving-car/geojson",
  // "v2/matrix/driving-car"
  const url = new URL(req.url);
  const subPath = url.pathname.replace(/^\/ors-proxy\/?/, '');
  if (!subPath) {
    return new Response('Missing ORS sub-path', { status: 400 });
  }

  const targetUrl = `${ORS_BASE}/${subPath}`;
  const body = req.method === 'POST' ? await req.text() : undefined;

  let orsResponse: Response;
  try {
    orsResponse = await fetch(targetUrl, {
      method: req.method,
      headers: {
        'Authorization': ORS_API_KEY,
        'Content-Type': 'application/json',
      },
      body,
    });
  } catch (e) {
    return new Response(`Upstream fetch failed: ${e}`, { status: 502 });
  }

  // Relayer la réponse telle quelle (status + body)
  return new Response(await orsResponse.text(), {
    status: orsResponse.status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
});
