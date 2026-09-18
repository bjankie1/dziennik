---
id: 260918-ev7
slug: librus-query-access-log-modal-and-tracki
title: Librus query access log modal and tracking
date: 2026-09-18
status: complete
commit: 478def3
---

# Quick Task Summary: Librus Query Access Log Modal & Tracking

Zrealizowano pełny moduł access loga dla zapytań HTTP do serwerów Librus Synergia wraz z technicznym przyciskiem w nagłówkach i interaktywnym oknem modalnym.

## Zrealizowane elementy

1. **Backend Interceptor & Firestore Access Log:**
   - Rozbudowano `LibrusClient` w `functions/src/librus_client.js` o interceptor zapytań i odpowiedzi mierzący czas trwania każdego zapytania HTTP z dokładnością do milisekund oraz wyciągający endpoint, metodę, status HTTP, treść błędu oraz rozmiar payloadu.
   - Dodano funkcję `deriveLibrusModule` klasyfikującą adresy URL do czytelnych modułów (`Oceny`, `Plan lekcji`, `Frekwencja`, `Wiadomości`, `Autoryzacja`, `Profil / Sesja`, `Cache`).
   - W `sync_service.js` zintegrowano automatyczny zapis każdego zapytania do kolekcji `librus_query_logs` w Firestore wraz z triggerem (`cron` vs `manual`), identyfikatorem uruchomienia `syncRunId` oraz rejestracją trafień do cache.
   - Wystawiono endpoint HTTP `/api/getLibrusLogs` w `functions/index.js` (oraz skonfigurowano rewrite w `firebase.json`) zwracający posortowaną historię zapytań.
   - Dodano 2 nowe testy jednostkowe w `functions/test/librus_query_logs.test.js` (14/14 testów backendowych przechodzi).

2. **Frontend Model, Serwis i Riverpod Provider:**
   - Stworzono model `LibrusQueryLog` (`lib/domain/models/librus_query_log.dart`) z parserem JSON i formatowaniem czasu, rozmiaru oraz wskaźników powodzenia/błędu/rate limitu.
   - Stworzono `LibrusLogService` (`lib/data/services/librus_log_service.dart`) z obsługą odpytywania API, fallbackiem do Firestore oraz przykładowymi logami offline.
   - Stworzono `librus_log_provider.dart` z zarządzaniem stanem, filtrami (wg modułu, tylko błędy/429, wyszukiwanie tekstowe) oraz obliczaniem wskaźników KPI (średni czas trwania, % sukcesu, liczba zapytań).

3. **Dialog modalny i techniczny przycisk:**
   - Zaimplementowano `LibrusQueryLogModal` (`lib/presentation/widgets/modals/librus_query_log_modal.dart`) z kafelkami KPI, filtrami, wyszukiwarką oraz tabelą z kolumnami: `CZAS`, `METODA`, `MODUŁ / ENDPOINT`, `TRIGGER`, `CZAS TRWANIA`, `STATUS`, `ROZMIAR`.
   - Zintegrowano techniczny przycisk z ikoną terminala (`Icons.terminal_rounded`, tooltip: `Dziennik zapytań Librus (Access Log)`) w:
     - `AppDesktopHeader` (wersja desktopowa, obok ikony powiadomień)
     - `AppHeader` (wersja mobilna, obok ikony synchronizacji i powiadomień).
   - Dodano testy jednostkowe modelu w `test/domain/models/librus_query_log_test.dart`.
   - `flutter analyze` — 0 błędów i ostrzeżeń.
