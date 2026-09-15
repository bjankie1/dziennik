# Stack Architecture

**Analysis Date:** 2026-09-15
**Project:** EduSync (Dziennik Szkolny)

## Languages & Runtimes
- **Dart:** 3.10.4+ (`sdk: ^3.10.4`) — Core application language for frontend web/mobile client.
- **Node.js:** 20.x (Google Cloud Functions v2) — Backend synchronization and scraping services.
- **JavaScript (ESM & CommonJS):** Node.js 20 runtime for Cloud Functions.

## Frameworks & Core Libraries
### Frontend (Flutter)
- **Flutter Web:** 3.38.5 / Material Design 3.
- **flutter_riverpod:** `^3.3.2` — Reactive state management and dependency injection.
- **firebase_core:** `^4.15.0` — Firebase client initialization.
- **firebase_auth:** `^6.7.0` — User authentication.
- **cloud_firestore:** `^6.10.0` — Realtime document database client.
- **http:** `^1.6.0` — REST client for Firebase Functions rewrites.
- **shared_preferences:** `^2.5.5` — Local device storage and session persistence.
- **intl:** `^0.20.3` — Polish localization and date formatting.
- **google_fonts:** `^8.2.1` — Academic Precision typography (Plus Jakarta Sans).

### Backend (Cloud Functions)
- **firebase-admin:** `^12.0.0` — Privileged access to Cloud Firestore and Auth.
- **firebase-functions:** `^5.0.0` (v2) — HTTPS endpoints and Cloud Scheduler triggers.
- **axios:** `^1.7.9` + **axios-cookiejar-support:** `^5.0.3` — Cookie-aware HTTP client.
- **tough-cookie:** `^5.0.0` — RFC 6265 cookie jar for Synergia session isolation.
- **cheerio:** `^1.0.0` — HTML parsing and extraction.

## Infrastructure & Hosting
- **Hosting:** Firebase Hosting (`lepsza-szkola.web.app`) with static cache-control and `/api/*` rewrites.
- **Functions:** Cloud Functions v2 (Region: `europe-west3` Frankfurt, memory: 256MiB–512MiB).
- **Scheduler:** Google Cloud Scheduler (Cron `every 30 minutes`, TimeZone: `Europe/Warsaw`).
- **Database:** Google Cloud Firestore (Native, Region: `europe-west3`).

*Codebase analysis: 2026-09-15*
