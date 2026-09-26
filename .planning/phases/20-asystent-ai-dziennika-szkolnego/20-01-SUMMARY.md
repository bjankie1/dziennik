---
phase: 20-asystent-ai-dziennika-szkolnego
plan: 01
subsystem: ai-assistant-core
tags: [firebase-ai, gemini-3.8-flash, gemini-3.1-pro, librus-sync, rag-context]
requires: []
provides:
  - "Incremental Librus full message body indexing & preservation across sync cycles (up to 40 messages)"
  - "AiChatMessage, AiSourceCitation, AiSuggestedEvent, AiSuggestedTask, AiModelTier domain models"
  - "SchoolAiContextBuilder with temporal Polish grounding and secret stripping"
  - "SchoolAiAssistantService integrating firebase_ai: ^4.0.0 (FirebaseAI.googleAI) with structured JSON schema and fallback"
affects:
  - functions/src/librus_client.js
  - functions/src/sync_service.js
  - functions/index.js
  - pubspec.yaml
  - lib/domain/models/ai_chat_message.dart
  - lib/core/services/school_ai_context_builder.dart
  - lib/core/services/school_ai_assistant_service.dart
tech-stack:
  added: ["firebase_ai: ^4.0.0"]
  patterns: ["Single-Pass Full-Context Grounding", "Structured Output Schema.object", "Incremental Stealth Background Indexing"]
key-files:
  created:
    - functions/test/message_body_indexing.test.js
    - lib/domain/models/ai_chat_message.dart
    - lib/core/services/school_ai_context_builder.dart
    - lib/core/services/school_ai_assistant_service.dart
    - test/ai_assistant_eval_test.dart
  modified:
    - functions/src/librus_client.js
    - functions/src/sync_service.js
    - functions/index.js
    - pubspec.yaml
key-decisions:
  - "Preserved already-fetched full message bodies (bodyLoaded: true) in sync_service.js and added incremental background fetching (4 messages/cycle up to 40 messages with 1200-2200ms jitter) so the AI knows about school trips and parent meetings inside generic message subjects."
  - "Integrated firebase_ai: ^4.0.0 using FirebaseAI.googleAI() with support for gemini-3.8-flash (default) and gemini-3.1-pro-preview, plus automatic fallback model chain and deterministic local analyzer."
requirements-completed:
  - REQ-AI-01
  - REQ-AI-02
duration: 10min
completed: 2026-09-26
---

# Phase 20 Plan 01: Backend Full Message Body Indexing & Flutter AI Service Summary

**Preserved and incrementally indexed up to 40 full Librus message bodies in Cloud Functions, and built the Flutter `firebase_ai: ^4.0.0` (`Gemini 3.8 Flash` / `3.1 Pro`) context builder and structured Q&A service.**

## Performance

- **Duration:** 10 min
- **Completed:** 2026-09-26
- **Tasks:** 2/2 completed
- **Files modified:** 9

## Accomplishments

- **Cloud Functions Full Message Body Indexing (`D-05`):** Updated `librus_client.js`, `sync_service.js` (`mergeAndIndexMessages`), and `functions/index.js` (`getMessageDetails`) to track `bodyLoaded: true`, preserve cached full message bodies across 15-minute sync overwrites, and incrementally index 4 unindexed messages per sync cycle (up to 40 messages) with stealth jitter (`1200–2200ms`).
- **AI Domain Models (`ai_chat_message.dart`):** Created `AiModelTier` (`⚡ 3.8 Flash` & `🧠 3.1 Pro`), `AiSourceCitation` (with route normalization to GoRouter paths), `AiSuggestedEvent` (integrated with `CalendarExportService`), `AiSuggestedTask`, and `AiChatMessage`.
- **Context Snapshot & Grounding (`school_ai_context_builder.dart`):** Built `SchoolAiContextBuilder` serializing Polish temporal headers, student profile, upcoming exams, weekly timetable, grades, attendance, tasks, announcements, and up to 35 full message bodies while stripping sensitive credentials (`encryptedPassword`, `parentPin`, `fcmToken`).
- **Firebase AI Logic Service (`school_ai_assistant_service.dart`):** Integrated `firebase_ai: ^4.0.0` via `FirebaseAI.googleAI()` with structured JSON `responseSchema`, multi-turn history window (last 10 turns), model fallback chain, and deterministic local Q&A analyzer.

## Task Commits

1. **Task 1: Preserve & Incrementally Index Full Librus Message Bodies in Cloud Functions** — `9a1ec2a`
2. **Task 2: Add `firebase_ai: ^4.0.0`, Create AI Domain Models, `SchoolAiContextBuilder` & `SchoolAiAssistantService`** — `HEAD`

## Verification

- `node --test functions/test/message_body_indexing.test.js` — 3/3 tests passed.
- `flutter test test/ai_assistant_eval_test.dart` — 3/3 evaluation tests passed.
- `flutter analyze` on all new AI files — 0 issues found.
