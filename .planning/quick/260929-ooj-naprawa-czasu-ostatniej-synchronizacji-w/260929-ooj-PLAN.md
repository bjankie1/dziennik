---
phase: quick-260929-ooj
plan: 01
type: execute
autonomous: true
files_modified:
  - lib/domain/models/student_profile.dart
  - lib/data/repositories/firestore_school_repository.dart
  - lib/presentation/providers/sync_provider.dart
  - lib/presentation/widgets/app_sidebar.dart
  - test/presentation/providers/sync_provider_test.dart
must_haves:
  truths:
    - "Status 'Ostatnia synchronizacja' pokazuje rzeczywisty czas ostatniej synchronizacji z Librusem zapisany przez backend (lastSyncTime / updatedAt), a nie czas otwarcia aplikacji"
    - "Etykieta dnia jest poprawna (dzisiaj / wczoraj / dd.MM), zamiast zawsze 'dzisiaj'"
    - "Czas nigdy nie jest pokazywany z przyszłości"
---

<objective>
Naprawa statusu synchronizacji: o 17:45 pokazywał „dzisiaj o 17:58”.

Przyczyna: `SyncState.lastSyncTime` był ustawiany na `DateTime.now()` przy starcie aplikacji
(a nie z backendu), a `formattedLastSync` dla wartości starszych niż 60 min zawsze
doklejał „dzisiaj”. Karta/PWA otwarta wczoraj o 17:58 i wznowiona dziś pokazywała więc
„dzisiaj o 17:58”.
</objective>

<tasks>
<task type="auto">
  <name>Task 1: Rzeczywisty czas synchronizacji z backendu + poprawne formatowanie</name>
  <action>
    1. `StudentProfile.lastSyncTime` (DateTime?) parsowany w repozytorium z `lastSyncTime` (ISO UTC) lub `updatedAt` (Timestamp), konwertowany do czasu lokalnego.
    2. `SyncState.lastSyncTime` nullable; `SyncNotifier` nasłuchuje `studentProfileProvider` i ustawia czas z serwera.
    3. `formattedLastSync`: przed chwilą / N min temu / dzisiaj o HH:mm / wczoraj o HH:mm / dd.MM o HH:mm; przyszłe czasy przycinane do „przed chwilą”; null → „brak danych”.
    4. Sidebar: usunąć zahardkodowane „Dzisiaj,”.
  </action>
  <verify><automated>flutter analyze && flutter test test/presentation/providers/sync_provider_test.dart</automated></verify>
</task>
</tasks>
