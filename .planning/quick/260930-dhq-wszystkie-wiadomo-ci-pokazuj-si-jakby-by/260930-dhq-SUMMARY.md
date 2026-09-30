---
phase: quick-260930-dhq
plan: 01
subsystem: messages
tags: [messages, timestamps, librus, ui, date-formatting]
requires: []
provides:
  - "MessageThread.formatTimestamp oraz getter formattedTimestamp dla spójnego formatowania dat wiadomości"
  - "FirestoreSchoolRepository.parseMessageDate dla odpornego parsowania dat z Librusa i Firestore"
  - "Dynamiczne wyświetlanie rzeczywistej daty i godziny na kartach wiadomości w MessagesScreen, DashboardMessagesColumn i DashboardMobileView"
affects:
  - lib/domain/models/message_thread.dart
  - lib/data/repositories/firestore_school_repository.dart
  - lib/presentation/screens/messages/messages_screen.dart
  - lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart
  - lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart
  - functions/src/librus_client.js
tech-stack:
  added: []
  patterns:
    - "Centralized Polish relative message date formatting on MessageThread domain model"
    - "Resilient multi-format date parser in FirestoreSchoolRepository.parseMessageDate"
key-files:
  created:
    - test/presentation/screens/messages_timestamp_test.dart
  modified:
    - lib/domain/models/message_thread.dart
    - lib/data/repositories/firestore_school_repository.dart
    - lib/presentation/screens/messages/messages_screen.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart
    - functions/src/librus_client.js
decisions:
  - "Przeniesiono logikę formatowania czasu wiadomości do MessageThread.formatTimestamp (Dzisiaj, HH:mm / Wczoraj, HH:mm / d MMM, HH:mm / d MMM yyyy, HH:mm z pominięciem sztucznego 00:00 dla dat bez godziny)"
  - "Wprowadzono odporny parser FirestoreSchoolRepository.parseMessageDate obsługujący formaty ISO/SQL, wieloliniowe ciągi z Librusa, format DD.MM.YYYY oraz obiekty Timestamp/{_seconds}"
metrics:
  duration: "7 min"
  completed_date: "2026-09-30"
  tasks: 2
  files: 7
  commits: 2
  plan_head_before: "407d8442f03415e8a6d6cbfc2acdaabbe8e00419"
status: complete
---

# Quick Task 260930-dhq: Naprawa wyświetlania dat i godzin wiadomości Summary

**Zastąpienie zahardkodowanej etykiety `'Dzisiaj, 09:15'` z makiety HTML na kartach wiadomości dynamicznym formaterem `thread.formattedTimestamp` oraz odpornym parserem dat z Librusa.**

## Completed Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Dodanie formatera dat w MessageThread, odpornego parsera w repozytorium i zastąpienie stałej etykiety na kartach wiadomości | `a7171f6` | `lib/domain/models/message_thread.dart`, `lib/data/repositories/firestore_school_repository.dart`, `lib/presentation/screens/messages/messages_screen.dart`, `lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart`, `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart`, `functions/src/librus_client.js` |
| 2 | Testy jednostkowe i widgetowe wyświetlania rzeczywistych dat wiadomości | `80f6fea` | `test/presentation/screens/messages_timestamp_test.dart` |

## What Changed

1. **Przyczyna błędu:** W `MessagesScreen._buildMessageCard` (`lib/presentation/screens/messages/messages_screen.dart`, linia 403) znajdował się zahardkodowany ciąg `'Dzisiaj, 09:15'` pozostały po makiecie HTML, przez co każda wiadomość na liście pokazywała tę samą datę i godzinę niezależnie od wartości `thread.timestamp`.
2. **Model `MessageThread` (`lib/domain/models/message_thread.dart`):**
   - Dodano metodę `MessageThread.formatTimestamp(DateTime timestamp, {DateTime? now})` oraz getter `formattedTimestamp`.
   - Wiadomości z dzisiaj wyświetlają `Dzisiaj, HH:mm`, z wczoraj `Wczoraj, HH:mm`, starsze z bieżącego roku `d MMM, HH:mm` (lub `d MMM` gdy brak godziny `00:00:00`), a z poprzednich lat `d MMM yyyy, HH:mm`.
3. **Widok Wiadomości i Pulpit (`messages_screen.dart`, `dashboard_messages_column.dart`, `dashboard_mobile_view.dart`):**
   - Zastąpiono stały tekst `'Dzisiaj, 09:15'` w `MessagesScreen._buildMessageCard` wywołaniem `thread.formattedTimestamp`.
   - Ujednolicono formatowanie dat wiadomości na Pulpicie (desktop i mobile) przez użycie `msg.formattedTimestamp`.
4. **Odporne parsowanie dat (`firestore_school_repository.dart`, `librus_client.js`):**
   - Dodano `FirestoreSchoolRepository.parseMessageDate` obsługujące formaty `YYYY-MM-DD HH:MM:SS`, ciągi z wieloma białymi znakami/nowymi liniami, `YYYY-MM-DD`, `DD.MM.YYYY HH:MM`, `Timestamp` oraz `{_seconds}`.
   - Znormalizowano białe znaki przy odczycie daty w `LibrusClient.fetchMessages`.
5. **Testy (`test/presentation/screens/messages_timestamp_test.dart`):**
   - Dodano 11 testów jednostkowych i widgetowych weryfikujących `MessageThread.formatTimestamp`, `FirestoreSchoolRepository.parseMessageDate` oraz renderowanie kart wiadomości na ekranie `MessagesScreen`.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `flutter analyze` — `No issues found!`
- `flutter test test/presentation/screens/messages_timestamp_test.dart` — 11/11 passed
- `flutter test test/message_attachments_test.dart` — 7/7 passed
- `cd functions && npm test` — 79/79 passed

## Self-Check: PASSED
