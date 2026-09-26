# Phase 20: Asystent AI dziennika szkolnego — Technical Research

**Phase:** 20 — Asystent AI dziennika szkolnego (Konwersacyjny agent Q&A)
**Requirements:** `REQ-AI-01`, `REQ-AI-02`
**Date:** 2026-09-24
**Status:** Complete

---

## 1. Research Summary & Key Findings

### 1.1 Critical Finding: Librus Message Body Overwrite & Partial Indexing Bug
During inspection of `functions/src/librus_client.js` (`fetchMessages()`, lines 659–702) and `functions/src/sync_service.js` (`syncLibrusData`, line 305), we identified two critical issues that would prevent the AI Assistant from answering questions like *"Kiedy jest wycieczka Oskara do Warszawy?"* or *"Kiedy jest zebranie z rodzicami?"*:
1. **Top-10 Limit with Subject Fallback:** `librus_client.js` initializes every scraped message with `body: subject` and `preview: subject`, and only fetches the real HTML `div.container-message-content` for the top 10 messages (`toFetchDetails = messages.slice(0, 10)`).
2. **Sync Overwrite:** `sync_service.js` executes `await studentRef.set({ ...freshData, ... }, { merge: true })`. Because `messages` is a top-level array field on `students/{login}`, Firestore replaces the entire `messages` array on every 15-minute sync! Any message beyond index 9 whose full `body` was previously loaded on-demand via `getMessageDetails` (`functions/index.js` lines 454–474) gets overwritten back to `body: subject`.

**Architecture Solution (Plan `20-01` Task 1):**
- Add an explicit boolean flag `bodyLoaded: true` whenever `librus_client.js` (`fetchMessages` or `fetchMessageDetails`) or `functions/index.js` (`getMessageDetails`) fetches the real `div.container-message-content`. Initialize unindexed list rows with `bodyLoaded: false`.
- Create a pure helper function `mergeAndIndexMessages({ freshMessages, prevMessages, client, maxIncrementalFetch = 4, maxIndexDepth = 40 })` in `functions/src/sync_service.js` (or exported for unit testing):
  1. **Preserve cached bodies:** For every message in `freshMessages`, if ` !m.bodyLoaded` and `prevMessages` has a matching message (`prev.id === m.id`) where `prev.bodyLoaded === true` (or `prev.body && prev.body !== prev.subject`), copy `body`, `preview`, and `bodyLoaded: true` from `prev`.
  2. **Incremental background indexing (D-05):** Find up to `maxIncrementalFetch` (default `4`) messages within the top `maxIndexDepth` (`40`) where `!m.bodyLoaded && m.librusUrl`. Fetch their full details via `client.fetchMessageDetails(m.id, m.librusUrl)` with stealth jitter (`1200–2200ms` via `client.sleep`), setting `body`, `preview`, and `bodyLoaded: true`.
  3. Within 5–7 background sync cycles, all 35–40 newest messages in Firestore will permanently have full `body` text (`bodyLoaded: true`) without triggering Librus rate-limiting.

---

### 1.2 Firebase AI Logic (`firebase_ai: ^4.0.0`) & Gemini 3 Model Strategy
- **SDK Compatibility:** `pub.dev` confirms `firebase_ai: ^4.0.0` is the official Flutter SDK replacing `firebase_vertexai`, compatible with our project's `firebase_core: ^4.15.0` and `firebase_auth: ^6.7.0`.
- **Initialization (D-03):**
  ```dart
  final ai = FirebaseAI.googleAI(auth: FirebaseAuth.instance);
  final model = ai.generativeModel(
    model: modelTier.modelId, // 'gemini-3.8-flash' or 'gemini-3.1-pro-preview'
    systemInstruction: Content.system(systemPrompt),
    generationConfig: GenerationConfig(
      temperature: 0.2,
      responseMimeType: 'application/json',
      responseSchema: aiResponseSchema,
    ),
  );
  ```
- **Model Availability Fallback:** Because Gemini model aliases on the Gemini Developer API Free Tier can vary by rollout region (`gemini-3.8-flash` vs `gemini-flash-latest` / `gemini-2.5-flash`), `SchoolAiAssistantService` will attempt the selected model (`gemini-3.8-flash` or `gemini-3.1-pro-preview`) first, and if a model-not-found / unsupported error occurs on `gemini-3.8-flash`, automatically retry with `gemini-flash-latest` so the user never experiences a hard crash.
- **Offline / Unconfigured Demo Fallback:** If Firebase AI Logic API is not yet enabled in Google Cloud Console or the app is running in offline/mock mode, `SchoolAiAssistantService` also includes a local deterministic search fallback over the `SchoolAiContextBuilder` snapshot (searching exams, messages, grades, timetable, and attendance for matching Polish keywords) and clearly informs the user if an API error occurred.

---

### 1.3 Context Snapshot & Security Guardrails (`SchoolAiContextBuilder`)
- **Single-Pass Grounding:** All school data for the active student (`grades`, `lessons`, `exams`, `attendance`, `messages`, `announcements`, `customTasks`, `homework`, `luckyNumber`) is already loaded in Riverpod providers and/or `students/{studentId}` in Firestore totaling ~15–35 KB (~8k–15k tokens).
- **Strict Secret Filtering:** `SchoolAiContextBuilder` explicitly builds its snapshot from typed domain models (`Grade`, `Lesson`, `Exam`, `Attendance`, `SchoolMessage`, `Announcement`, `CustomTask`, `Homework`) and NEVER reads raw Firestore map fields like `encryptedPassword`, `parentPin`, or `fcmTokens`. A dedicated unit test in `test/ai_assistant_eval_test.dart` verifies that no secret strings can leak into the context prompt.
- **Temporal Grounding:** Injects exact current Polish date, day of week (`poniedziałek`–`niedziela`), and tomorrow's date so relative queries (*"jutro"*, *"w tym tygodniu"*, *"następny sprawdzian"*) resolve without date hallucination.

---

### 1.4 UI Architecture: Floating Chat Button + Panel & `/czat` Mode Switcher
- **D-01 & D-02 Compliance:**
  - `AppSidebar` (`lib/presentation/widgets/navigation/app_sidebar.dart`) and mobile `NavigationBar` (`lib/presentation/widgets/navigation/main_navigation_screen.dart`) keep their existing 7 navigation destinations unchanged.
  - In `MainNavigationScreen`, we mount `FloatingChatFab` + `FloatingChatPanel` inside a `Stack` wrapping `widget.navigationShell` (automatically hidden when the user is already on `/czat` route index 5 so two chat UIs don't overlap).
  - Both `FloatingChatPanel` and `FamilyChatScreen` (`/czat`) feature the segmented header switcher:
    - **`👨‍👦 Czat: Oskar / Tata`** (existing family chat with quick chips)
    - **`✨ Asystent AI`** (`AiAssistantChatView` with model selector `⚡ 3.8 Flash` / `🧠 3.1 Pro`, `Wyczyść czat`, starter prompt chips, clickable `AiSourceCitationsRow`, and `+ Kalendarz Google` / `+ Dodaj zadanie` quick actions).
- **Per-Role Firestore History (D-07):**
  - Stored in `students/{studentId}/ai_chats/{role}/messages/{messageId}` (`role` = `'parent'` or `'student'`).
  - Covered by existing `firestore.rules` wildcard rule (`match /students/{studentId} { match /{allChildren=**} { allow read, write: if true; } }`).

---

## 2. Validation Architecture (Nyquist Compliance)

| Layer | Test Suite | What It Verifies |
|-------|------------|------------------|
| **Backend (Node.js)** | `functions/test/message_body_indexing.test.js` | 1. Preserves cached `body` and `bodyLoaded: true` from `prevData.messages` during sync.<br>2. Incrementally fetches up to 4 unindexed message bodies per sync cycle with jitter.<br>3. Caps incremental indexing at top 40 messages and handles fetch errors gracefully. |
| **Flutter Unit / Eval** | `test/ai_assistant_eval_test.dart` | 1. `SchoolAiContextBuilder` includes full message bodies (e.g. Warsaw trip, parent meeting), upcoming exams, timetable, grades, attendance, and Polish temporal header.<br>2. `SchoolAiContextBuilder` strips/excludes all credentials (`encryptedPassword`, `parentPin`).<br>3. `AiChatMessage` JSON schema parsing & fallback serialization (`sources`, `suggestedEvent`, `suggestedTask`).<br>4. Deterministic local Q&A fallback accurately answers *"Kiedy jest następny sprawdzian?"*, *"Kiedy jest wycieczka Oskara do Warszawy?"*, and *"Kiedy jest zebranie z rodzicami?"* with valid source citations. |
| **Static Analysis** | `flutter analyze` | Zero errors/warnings across all new Dart models, services, providers, and UI widgets. |
