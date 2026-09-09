# Clarivo — Deployment Guide

Clarivo ships as a **Progressive Web App (PWA)**. A single Flutter Web build
serves the landing page and the full app. Android and Windows users install it
through the browser's PWA install flow (no APK, no store, no installer).

---

## How the Groq API key is protected

There are two run modes, selected automatically at build time:

- **Local development — direct mode.** When you build/run with
  `--dart-define=GROQ_API_KEY=...`, Clara calls the Groq API directly using
  that key. Convenient for local work.

- **Production — proxy mode.** When **no** key is baked into the build (the
  production default), Clara instead calls the app's own serverless proxy at
  `/api/clara`. The proxy (`netlify/functions/clara.js`) adds the real key
  **server-side** from the `GROQ_API_KEY` Netlify environment variable and
  forwards the request to Groq. **The key never reaches the browser.**

Groq request parameters (model `qwen/qwen3.8-27b`, temperature `0.3`,
`max_tokens 950`) are identical in both modes, so answers are unchanged.

---

## Deploy to Netlify (recommended)

Netlify uses `netlify.toml`, which is already configured to:
- build the web release **without** embedding the key (proxy mode),
- publish `build/web`,
- deploy the function in `netlify/functions`,
- route `/api/clara` → the `clara` function,
- serve the SPA fallback and security headers.

Steps:

1. **Push the repo to GitHub/GitLab** and create a new Netlify site from it
   (or use `netlify deploy` with the Netlify CLI).
2. **Set the environment variable** in Netlify:
   - Site settings → Environment variables → add
     `GROQ_API_KEY = gsk_your_key_here`
   - This is the ONLY place the production key lives. Do not commit it.
3. **Trigger a deploy.** Netlify runs the build command in `netlify.toml`
   (clones Flutter stable, `flutter pub get`, `flutter build web --release`),
   publishes `build/web`, and deploys the `clara` function.
4. **Verify:** open the site, ask Clara a question, and confirm you get an
   answer. In the browser Network tab you should see a request to
   `/api/clara` (not to `api.groq.com`), and the key must not appear anywhere
   in the page source or JS bundle.

### Local preview of the full stack (optional)

To test the function + app together locally, use the Netlify CLI:

```bash
npm install -g netlify-cli
netlify dev            # serves the app and the /api/clara function
```

Set `GROQ_API_KEY` in your shell (or a Netlify-linked env) so the function can
read it.

---

## Local development (direct mode)

Run from the project root:

```bash
# Dev server
flutter run -d chrome --dart-define=GROQ_API_KEY=gsk_your_key

# One-off release build with the key embedded (local testing only —
# do NOT deploy this build publicly, as the key would be in the bundle)
flutter build web --release --dart-define=GROQ_API_KEY=gsk_your_key
```

The `.env` file is only a convenience for storing your local key; the key is
passed via `--dart-define`, not read from `.env` at runtime. `.env` is
git-ignored and must never be committed.

---

## PWA install (what users do)

- **Android (Chrome):** open the site → ⋮ menu → "Add to Home screen" /
  "Install app". The landing page "Install on Android" button triggers this
  automatically when the browser offers it.
- **Windows (Chrome/Edge):** open the site → install icon in the address bar,
  or ⋮ → "Install this site as an app". The "Install for Windows" button
  triggers the native prompt; it then opens in its own window with a desktop /
  Start Menu shortcut.

---

## Security checklist before going live

- [ ] `GROQ_API_KEY` is set as a **Netlify environment variable**, not embedded
      in the build.
- [ ] The production build was made **without** `--dart-define=GROQ_API_KEY`
      (Netlify's build command already omits it).
- [ ] Requests go to `/api/clara`; the key is absent from the JS bundle and
      page source.
- [ ] `.env` is git-ignored and not present in git history.
- [ ] Rotate the Groq key if it has ever been shared or embedded in a public
      build.
- [ ] Security headers are served (configured in `netlify.toml`).

> Note: `android/`, `ios/`, and `windows/` folders remain as default Flutter
> scaffolding but are not part of the shipped build path. Clarivo is delivered
> as a PWA.

---

## Troubleshooting (lessons learned)

Two issues that broke the live site during initial deploy, and how they were fixed:

1. **`/api/clara` returned a 404 / the app HTML instead of the function.**
   Cause: `web/_redirects` had only the SPA catch-all (`/* /index.html 200`),
   and a `_redirects` file takes precedence over `netlify.toml` redirects — so
   the catch-all swallowed `/api/clara` before it could reach the function.
   Fix: put the function route **before** the catch-all in `web/_redirects`,
   using a forced rule:
   ```
   /api/clara    /.netlify/functions/clara    200!
   /*            /index.html                  200
   ```

2. **The function returned "GROQ_API_KEY is missing" even though the variable existed.**
   Cause: environment-variable changes only take effect on a **new deploy**,
   and the variable must be present in the **Production** deploy context with
   the **Functions** scope enabled.
   Fix: after adding/changing `GROQ_API_KEY`, always trigger a fresh deploy
   (Deploys → Trigger deploy → Deploy site), and confirm the Production context
   has a value.

3. **Build failed with "demo_database.g.dart is missing."**
   Cause: generated `*.g.dart` files are git-ignored, so Netlify never received
   them. Fix: the Netlify build command runs `dart run build_runner build`
   before `flutter build web` to regenerate them (see `netlify.toml`).

### Quick health check of the deployed function
```bash
# Should return JSON {"content":"..."} (not HTML, not a 404/500)
curl -X POST https://<your-site>.netlify.app/api/clara \
  -H "Content-Type: application/json" \
  -d '{"systemPrompt":"You are a test.","userMessage":"Reply with OK"}'
```
