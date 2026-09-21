# Phase 13: Technical Research — Dedykowane URL i routing dla podstron i zasobów (deep linking)

## 1. Wybór narzędzi i bibliotek
- **`go_router`** (wersja `^17.5.0` dodana do `pubspec.yaml`):
  - Oficjalny pakiet Flutter Team oparty na Navigator 2.0.
  - Zapewnia deklaratywne definiowanie tras (`GoRoute`), `ShellRoute` / `StatefulShellRoute` (idealne dla zachowania stanu zakładek z `AppSidebar` i `IndexedStack`).
  - Pełna obsługa URL Path Strategy (`usePathUrlStrategy()` z `flutter_web_plugins/url_strategy.dart`).
  - Wbudowane wsparcie dla parametrów ścieżki (`:threadId`) oraz parametrów zapytania (`?data=...`, `?redirect=...`).

## 2. Architektura tras (Routing Schema)
- `/logowanie` -> `LoginScreen`
- `/polacz-librus` -> `LibrusConnectScreen`
- `StatefulShellRoute.indexedStack` dla `MainNavigationScreen`:
  - Trasa główna: `/` przekierowuje do `/pulpit`
  - Gałąź 0: `/pulpit` -> `DashboardScreen`
  - Gałąź 1: `/plan-lekcji` -> `ScheduleScreen` (opcjonalny query param `?data=YYYY-MM-DD` ustawia `selectedWeekMondayProvider` i `selectedScheduleDayProvider`)
  - Gałąź 2: `/oceny` -> `GradesScreen` (opcjonalny query param `?semestr=1|2`)
  - Gałąź 3: `/frekwencja` -> `AttendanceScreen` (opcjonalny query param `?filtr=0|1|2`)
  - Gałąź 4: `/wiadomosci` -> `MessagesScreen`
- Podtrasy podglądu zasobów:
  - `/wiadomosci/:threadId` -> `MessageThreadScreen` (otwiera konkretny wątek, z przyciskiem powrotu do `/wiadomosci`)

## 3. Integracja z Riverpod i Auth Guard
- `routerProvider`:
  - `ref.watch(authStateProvider)` oraz `ref.watch(librusConnectionStateProvider)` sterują parametrem `redirect` w `GoRouter`.
  - Jeżeli użytkownik nie jest zalogowany, a próbuje wejść na `/plan-lekcji?data=...`, `redirect` kieruje na `/logowanie?redirect=/plan-lekcji%3Fdata%3D...`.
  - Po pomyślnym zalogowaniu, użytkownik jest natychmiast przekierowywany na docelowy adres `redirect` lub domyślnie na `/pulpit`.

## 4. Nawigacja w UI (Synchronizacja)
- Dotychczasowe wywołania `ref.read(currentNavIndexProvider.notifier).setIndex(n)` zostają zastąpione lub zsynchronizowane z `context.go(path)`.
- W `MainNavigationScreen` zamiast lokalnego `currentIndex` używamy `navigationShell.currentIndex`, co zapewnia bezbłędną współpracę z przyciskami *Wstecz* i *Dalej* w przeglądarce oraz zmianą adresu w pasku URL.

## 5. Web Deployment i Hosting
- W `firebase.json` istnieje już reguła:
  ```json
  {
    "source": "**",
    "destination": "/index.html"
  }
  ```
- W `main.dart` wywołanie `usePathUrlStrategy()` usuwa znak `#` z adresów, co pozwala na czyste URL-e takie jak:
  `https://lepsza-szkola.web.app/plan-lekcji`
