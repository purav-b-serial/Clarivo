// Cloudflare Pages Function — proxy for Clara's Groq chat completions.
//
// This mirrors netlify/functions/clara.js but uses Cloudflare Pages Functions'
// conventions:
//   - File path maps to the route: functions/api/clara.js  ->  /api/clara
//     (so no redirect config is needed on Cloudflare).
//   - Handlers are named exports: onRequestPost / onRequestOptions.
//   - The Web platform Request/Response API is used (not Netlify's event/return).
//   - Secrets come from context.env (set GROQ_API_KEY in the Cloudflare Pages
//     project: Settings -> Environment variables). The key stays server-side
//     and never ships to the browser.
//
// Request  (from the app):  { "systemPrompt": string, "userMessage": string }
// Response (to the app):    { "content": string }   on success
//                           { "error": string }     on failure (non-2xx)

const GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';
const MODEL = 'qwen/qwen3.8-27b';
const MAX_CHARS = 20000;

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders(),
  });
}

// CORS preflight.
export async function onRequestOptions() {
  return new Response(null, { status: 204, headers: corsHeaders() });
}

// Any non-POST method that reaches this route.
export async function onRequest(context) {
  if (context.request.method === 'POST') {
    return onRequestPost(context);
  }
  if (context.request.method === 'OPTIONS') {
    return onRequestOptions();
  }
  return json({ error: 'Method not allowed. Use POST.' }, 405);
}

export async function onRequestPost(context) {
  const { request, env } = context;

  const apiKey = env.GROQ_API_KEY;
  if (!apiKey) {
    return json(
      {
        error:
          'Server is not configured: GROQ_API_KEY environment variable is missing on Cloudflare Pages.',
      },
      500,
    );
  }

  // Parse and validate the incoming request.
  let payload;
  try {
    payload = await request.json();
  } catch (_) {
    return json({ error: 'Invalid JSON body.' }, 400);
  }

  const systemPrompt =
    typeof payload.systemPrompt === 'string' ? payload.systemPrompt : '';
  const userMessage =
    typeof payload.userMessage === 'string' ? payload.userMessage : '';

  if (!userMessage.trim()) {
    return json({ error: 'userMessage is required.' }, 400);
  }

  const safeSystem = systemPrompt.slice(0, MAX_CHARS);
  const safeUser = userMessage.slice(0, MAX_CHARS);

  // Output token budget. Chat defaults to 950; quizzes/flashcards may request
  // more (via maxTokens) since a full 10-question JSON response needs room.
  // Hard-capped at 2000 to stay clear of Groq free-tier per-minute limits.
  const HARD_CAP = 2000;
  let maxTokens = 950;
  if (typeof payload.maxTokens === 'number' && payload.maxTokens > 0) {
    maxTokens = Math.min(Math.floor(payload.maxTokens), HARD_CAP);
  }

  const body = {
    model: MODEL,
    messages: [
      { role: 'system', content: safeSystem },
      { role: 'user', content: safeUser },
    ],
    temperature: 0.3,
    max_tokens: maxTokens,
  };

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 60000);

    const resp = await fetch(GROQ_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    const text = await resp.text();

    if (!resp.ok) {
      let message = text;
      try {
        const parsed = JSON.parse(text);
        message = parsed.error?.message || text;
      } catch (_) {
        /* keep raw text */
      }
      return json({ error: `Groq API error ${resp.status}: ${message}` }, resp.status);
    }

    const data = JSON.parse(text);
    const content = data.choices?.[0]?.message?.content ?? '';
    return json({ content }, 200);
  } catch (err) {
    const aborted = err && err.name === 'AbortError';
    return json(
      {
        error: aborted
          ? 'Clara timed out waiting for the AI service. Please try again.'
          : 'Could not reach the AI service. Please try again.',
      },
      aborted ? 504 : 502,
    );
  }
}
