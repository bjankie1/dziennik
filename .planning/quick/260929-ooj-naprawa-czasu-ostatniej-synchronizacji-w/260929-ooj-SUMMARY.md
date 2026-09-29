---
phase: quick-260929-ooj
plan: 01
status: complete
completed: "2026-09-29"
key-files:
  modified:
    - lib/domain/models/student_profile.dart
    - lib/data/repositories/firestore_school_repository.dart
    - lib/presentation/providers/sync_provider.dart
    - lib/presentation/widgets/app_sidebar.dart
    - test/presentation/providers/sync_provider_test.dart
---

# Quick Task 260929-ooj: Czas ostatniej synchronizacji w przyszłości

## Objaw
O 17:45 status pokazywał „Ostatnia synchronizacja: dzisiaj o 17:58”.

## Przyczyna
- `SyncState.lastSyncTime` był ustawiany na `DateTime.now()` klienta przy starcie aplikacji
  (nie był to rzeczywisty czas synchronizacji z backendu).
- `formattedLastSync` dla czasu starszego niż 60 min zawsze doklejał „dzisiaj”.
- Karta/PWA otwarta wczoraj o 17:58 i wznowiona dziś → „dzisiaj o 17:58”.

## Poprawka
- `StudentProfile.lastSyncTime` — parsowany z `lastSyncTime` (ISO UTC) lub `updatedAt`
  (Timestamp) zapisanych przez backend, konwertowany do czasu lokalnego.
- `SyncNotifier` pobiera czas z `studentProfileProvider` (bezpiecznie, `asData`) — zarówno
  po synchronizacji harmonogramowej, jak i na żądanie.
- `formatLastSync`: przed chwilą / N min temu / dzisiaj o / wczoraj o / dd.MM o;
  przyszłe czasy → „przed chwilą”; brak → „brak danych”.
- Pasek boczny: usunięto zahardkodowane „Dzisiaj,”.

## Testy
6 nowych testów regresyjnych w `sync_provider_test.dart` — przechodzą.
Test „initial state” nie przechodził już wcześniej (brak nadpisania
`sharedPreferencesProvider` w teście) — bez zmian.
