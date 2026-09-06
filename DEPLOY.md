# Clarivo - Deployment Guide

## Web (Landing Page + Online Demo)

### Netlify (recommended - 2 minutes)
1. flutter build web --release
2. Drag the build/web/ folder to https://app.netlify.com/drop
3. Copy the generated URL (e.g. https://abc123.netlify.app)
4. Update _apkUrl and _windowsUrl in lib/features/landing/landing_screen.dart
5. Rebuild and redeploy

### GitHub Pages
flutter build web --release --base-href /clarivo/
Then push build/web contents to gh-pages branch.

### Firebase Hosting
firebase init hosting   # public: build/web, SPA: yes
flutter build web --release
firebase deploy

---

## Android APK
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk

Upload APK to Google Drive / GitHub Release / Netlify.
Update _apkUrl in landing_screen.dart to the download link.
Testers: enable "Install from unknown sources" in Android Settings.

---

## Windows
flutter build windows --release
# Output: build/windows/x64/runner/Release/
Zip the Release/ folder, upload as clarivo-demo-windows.zip.
Update _windowsUrl in landing_screen.dart.

---

## Environment Variables

The .env file must contain GROQ_API_KEY and must NOT be committed to git.
  GROQ_API_KEY=gsk_...

For CI/CD, inject as environment secret:
  echo "GROQ_API_KEY=$GROQ_API_KEY" > .env
  flutter build web --release

SECURITY NOTE: The Groq API key is embedded in the Flutter Web bundle.
This is acceptable for a hackathon demo. For production, proxy all Groq
calls through a backend server so the key is never exposed to the browser.
