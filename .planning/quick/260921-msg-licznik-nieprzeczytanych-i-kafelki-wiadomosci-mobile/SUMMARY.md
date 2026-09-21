---
title: "Naprawa licznika nieprzeczytanych wiadomości oraz dodanie kafelków wiadomości na pulpicie mobilnym"
date: 2026-09-21
status: complete
---

# Summary: Licznik nieprzeczytanych wiadomości i kafelki na pulpicie mobilnym

## Zrealizowane zadania

1. **Poprawa detekcji nieprzeczytanych wiadomości w backendzie (`functions/src/librus_client.js`, `functions/src/sync_service.js`):**
   - Poprawiono metodę `fetchMessages()` tak, by sprawdzała pogrubienie na `tr`, `td` i linkach tematu, ikony stanu koperty (`nieprzeczytan`, `zamkniet`, `unread`) oraz licznik w nagłówku menu strony Librusa.
   - W `sync_service.js` dodano zapisywanie `unreadMessagesCount` w migawce studenta w Firestore.

2. **Inteligentne wyznaczanie stanu nieprzeczytania w repozytorium (`lib/data/repositories/firestore_school_repository.dart`):**
   - Respektowanie jawnych decyzji użytkownika (`_localReadOverrides`).
   - Nowe wiadomości odebrane dzisiaj, których użytkownik jeszcze nie otworzył w EduSync, są traktowane jako nieprzeczytane (`isUnread = true`).
   - Poprawiono mapowanie `unreadMessagesCount` w profilu studenta.

3. **Inwalidacja wiadomości i frekwencji przy synchronizacji (`lib/presentation/providers/sync_provider.dart`):**
   - Dodano `ref.invalidate(messagesProvider)` oraz `ref.invalidate(attendanceProvider)` w `syncNow()`.

4. **Nowa sekcja wiadomości na mobilnym pulpicie (`lib/presentation/screens/dashboard/dashboard_screen.dart`):**
   - W `_buildMobileDashboard` dodano kartę wiadomości z badge'em liczby nieprzeczytanych.
   - Baner informacyjny: "Masz X nowe wiadomości od nauczycieli".
   - Kafelki najnowszych wiadomości (`_buildMobileMessageItem`) z awatarem, nadawcą, datą, pogrubionym tematem, podglądem treści i kropką nieprzeczytanej wiadomości.
   - Kliknięcie kafelka natychmiast otwiera wątek przez `context.go('/wiadomosci/${msg.id}', extra: msg)`.
   - Przycisk "Wszystkie →" prowadzący do pełnej skrzynki odbiorczej.

## Weryfikacja
- `npm test` w `functions` — 18/18 testów zdanych.
- `flutter analyze` — 0 błędów, 0 ostrzeżeń.
- `flutter build web --release` — kompilacja zakończona sukcesem.
- Wdrożenie na Firebase Hosting i Cloud Functions (`europe-west3`) — wersja opublikowana.
