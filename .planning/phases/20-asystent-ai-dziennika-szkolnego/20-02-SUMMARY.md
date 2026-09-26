---
phase: 20-asystent-ai-dziennika-szkolnego
plan: 02
subsystem: ai-assistant-ui
tags: [riverpod, floating-chat, gemini-3.8-flash, gemini-3.1-pro, citations, google-calendar]
requires:
  - 20-01
provides:
  - "ai_assistant_provider.dart with per-role Firestore AI chat history (students/{id}/ai_chats/{role}/messages) and Gemini model selector"
  - "AiSourceCitationsRow with clickable GoRouter deep links and + Kalendarz Google / + Dodaj zadanie quick actions"
  - "AiAssistantChatView with starter prompt chips, Gemini 3 model switcher (⚡ 3.8 Flash ↔ 🧠 3.1 Pro), and Wyczyść czat"
  - "FloatingChatFab and FloatingChatPanel overlay in MainNavigationScreen without adding an 8th navigation tab"
  - "Dual-mode segmented header switcher (👨‍👦 Czat: Oskar/Tata ↔ ✨ Asystent AI) in both FloatingChatPanel and FamilyChatScreen (/czat)"
affects:
  - lib/presentation/providers/ai_assistant_provider.dart
  - lib/presentation/widgets/chat/ai_source_citations_row.dart
  - lib/presentation/widgets/chat/ai_assistant_chat_view.dart
  - lib/presentation/widgets/chat/floating_chat_panel.dart
  - lib/presentation/widgets/chat/floating_chat_fab.dart
  - lib/presentation/screens/chat/family_chat_screen.dart
  - lib/presentation/screens/main_navigation_screen.dart
tech-stack:
  added: []
  patterns: ["Floating Dual-Mode Chat Overlay", "Per-Role Firestore Subcollection Stream", "Interactive Citation Pills & Quick Actions"]
key-files:
  created:
    - lib/presentation/providers/ai_assistant_provider.dart
    - lib/presentation/widgets/chat/ai_source_citations_row.dart
    - lib/presentation/widgets/chat/ai_assistant_chat_view.dart
    - lib/presentation/widgets/chat/floating_chat_panel.dart
    - lib/presentation/widgets/chat/floating_chat_fab.dart
  modified:
    - lib/presentation/screens/chat/family_chat_screen.dart
    - lib/presentation/screens/main_navigation_screen.dart
key-decisions:
  - "Kept AppSidebar and mobile NavigationBar at 7 items (no 8th tab, D-01) and mounted FloatingChatFab + FloatingChatPanel inside MainNavigationScreen Stack."
  - "Shared ChatModeSegmentedSwitcher between FloatingChatPanel and FamilyChatScreen (/czat) so users can toggle between Family Chat and AI Assistant in both compact and full-screen views."
requirements-completed:
  - REQ-AI-01
  - REQ-AI-02
duration: 10min
completed: 2026-09-26
---

# Phase 20 Plan 02: Riverpod AI Providers, Floating Chat Widget & Dual-Mode UI Summary

**Built the per-role Firestore AI conversation provider, interactive citation & quick-action pills, `FloatingChatFab` + `FloatingChatPanel` overlay, and dual-mode `FamilyChatScreen` (`👨‍👦 Czat: Oskar/Tata` ↔ `✨ Asystent AI`).**

## Performance

- **Duration:** 10 min
- **Completed:** 2026-09-26
- **Tasks:** 2/2 completed
- **Files modified:** 7

## Accomplishments

- **Riverpod State & Per-Role History (`ai_assistant_provider.dart`):** Implemented `activeChatModeProvider`, `isFloatingChatOpenProvider`, `selectedAiModelProvider` (`⚡ 3.8 Flash` default ↔ `🧠 3.1 Pro`), `AiChatRepository` (streaming `students/{studentId}/ai_chats/{roleKey}/messages` isolated per `'parent'` vs `'student'`), and `AiChatActions` (`askQuestion`, `clearHistory`).
- **Interactive Citations & Quick Actions (`ai_source_citations_row.dart`):** Rendered clickable source pills (`📩 Wiadomość`, `📅 Plan lekcji`, `🎓 Oceny`, `📋 Frekwencja`, `📌 Zadania`) navigating via GoRouter, plus `+ Kalendarz Google` (`CalendarExportService.openGoogleCalendar`) and `+ Dodaj zadanie` (`TasksRepository.addTask`).
- **Conversational AI View (`ai_assistant_chat_view.dart`):** Built the empty state with 5 starter prompt chips (*"Kiedy jest następny sprawdzian?"*, *"Kiedy jest wycieczka Oskara do Warszawy?"*, *"Kiedy jest zebranie z rodzicami?"*, etc.), model switcher dropdown, typing indicator, bold Markdown text renderer, and clear chat confirmation dialog.
- **Floating Chat Overlay & `/czat` Switcher (`floating_chat_fab.dart`, `floating_chat_panel.dart`, `family_chat_screen.dart`, `main_navigation_screen.dart`):** Added `FloatingChatFab` and `FloatingChatPanel` (`410x580` card on desktop, `86%` bottom sheet on mobile) to `MainNavigationScreen` without adding an 8th navigation tab, and integrated `ChatModeSegmentedSwitcher` into `FamilyChatScreen`.

## Task Commits

1. **Task 1: Create `ai_assistant_provider.dart` with Per-Role Firestore History, Model Selector & Context Gathering** — `e4d81cd`
2. **Task 2: Build AI Chat Widgets & Integrate into `FamilyChatScreen` and `MainNavigationScreen`** — `HEAD`

## Verification

- `flutter analyze` across entire project — 0 issues found.
- `flutter test test/ai_assistant_eval_test.dart` — 3/3 tests passed.
