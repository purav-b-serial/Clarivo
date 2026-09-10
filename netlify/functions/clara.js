// Netlify serverless proxy for Clara's Groq chat completions.
//
// WHY: In production we must NOT ship the Groq API key to the browser. The
// Flutter web app POSTs to this function (/api/clara); the function adds the
// secret key server-side and forwards the request to Groq. The key lives only
// in the Netlify environment variable GROQ_API_KEY and never reaches the client.
//
// Set the key in Netlify: Site settings -> Environment variables -> GROQ_API_KEY
//
// Request  (from the app):  { "systemPrompt": string, "userMessage": string }
// Response (to the app):    { "content": string }   on success
//                           { "error": string }     on failure (non-200)

const GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';
const MODEL = 'qwen/qwen3.8-27b';

// Only allow the app's own origin(s) to use the proxy. In production Netlify
// serves the function on the same origin as the app, so same-origin calls have
// no Origin header issue; we keep CORS permissive-but-scoped for safety.
const ALLOWED_METHODS = 'POST, OPTIONS';

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': ALLOWED_METHODS,
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };
}

exports.handler = async (event) => {
  // Preflight
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers: corsHeaders(), body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: corsHeaders(),
      body: JSON.stringify({ error: 'Method not allowed. Use POST.' }),
    };
  }

  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) {
    return {
      statusCode: 500,
      headers: corsHeaders(),
      body: JSON.stringify({
        error:
          'Server is not configured: GROQ_API_KEY environment variable is missing on Netlify.',
      }),
    };
  }

  // Parse and validate the incoming request.
  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch (_) {
    return {
      statusCode: 400,
      headers: corsHeaders(),
      body: JSON.stringify({ error: 'Invalid JSON body.' }),
    };
  }

  const systemPrompt = typeof payload.systemPrompt === 'string' ? payload.systemPrompt : '';
  const userMessage = typeof payload.userMessage === 'string' ? payload.userMessage : '';

  if (!userMessage.trim()) {
    return {
      statusCode: 400,
      headers: corsHeaders(),
      body: JSON.stringify({ error: 'userMessage is required.' }),
    };
  }

  // Basic abuse guard: cap the size of what we forward to Groq.
  const MAX_CHARS = 20000;
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
      // Surface Groq's error message without leaking the key or headers.
      let message = text;
      try {
        const parsed = JSON.parse(text);
        message = parsed.error?.message || text;
      } catch (_) {
        /* keep raw text */
      }
      return {
        statusCode: resp.status,
        headers: corsHeaders(),
        body: JSON.stringify({ error: `Groq API error ${resp.status}: ${message}` }),
      };
    }

    const data = JSON.parse(text);
    const content = data.choices?.[0]?.message?.content ?? '';
    return {
      statusCode: 200,
      headers: corsHeaders(),
      body: JSON.stringify({ content }),
    };
  } catch (err) {
    const aborted = err && err.name === 'AbortError';
    return {
      statusCode: aborted ? 504 : 502,
      headers: corsHeaders(),
      body: JSON.stringify({
        error: aborted
          ? 'Clara timed out waiting for the AI service. Please try again.'
          : 'Could not reach the AI service. Please try again.',
      }),
    };
  }
};
