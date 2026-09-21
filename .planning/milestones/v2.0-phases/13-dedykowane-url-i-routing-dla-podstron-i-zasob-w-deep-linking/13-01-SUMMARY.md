# Plan 13-01: Architektura routingu webowego: go_router, Path URL Strategy i integracja z Auth/Shell — Summary

**Phase:** 13 — dedykowane-url-i-routing-dla-podstron-i-zasob-w-deep-linking  
**Plan ID:** 13-01  
**Status:** Completed  
**Completed Date:** 2026-09-21  

---

## 1. Executive Summary

Plan 13-01 wdrożył w aplikacji internetowej EduSync nowoczesny, deklaratywny routing oparty o pakiet `go_router`:
1. **Path URL Strategy (HTML5 History API):** Włączono `usePathUrlStrategy()`, eliminując hashe (`/#/`) z adresów URL na rzecz czystych ścieżek (`/pulpit`, `/plan-lekcji`, `/oceny`, `/frekwencja`, `/wiadomosci`).
2. **StatefulShellRoute (IndexedStack):** Zastosowano `StatefulShellRoute.indexedStack`, integrując go z `MainNavigationScreen`, `AppSidebar`, `AppDesktopHeader` oraz `NavigationBar` (wersja mobilna). Zmiana zakładek zachowuje stan (scroll, filtry, wybrane elementy), aktualizując jednocześnie pasek adresu przeglądarki i wspierając historię Wstecz/Dalej.
3. **Guardy autoryzacyjne i obsługa powrotu (`?redirect=...`):** `appRouterProvider` weryfikuje stan sesji Firebase oraz połączenia z Librusem. W przypadku próby wejścia na chronioną podstronę bez sesji, użytkownik trafia na `/logowanie?redirect=...`, a po udanej autoryzacji wraca bezpośrednio pod żądany adres URL.
4. **Aktualizacja nawigacji na Pulpicie:** Wszystkie przyciski nawigacyjne ("Pełny plan lekcji", "Zobacz wszystkie oceny", "Otwórz skrzynkę", "Zadania domowe") zostały zaktualizowane z bezpośrednich modyfikacji indeksu na przejścia deklaratywne `context.go(...)`.

---

## 2. Tasks Completed & Changes

| Task | Opis | Pliki |
|---|---|---|
| **Task 1** | Konfiguracja `appRouterProvider` w `lib/presentation/routes/app_router.dart`, obsługa guardów redirect, włączenie `usePathUrlStrategy()` w `lib/main.dart` | `lib/presentation/routes/app_router.dart`, `lib/main.dart` |
| **Task 2** | Refaktoryzacja `MainNavigationScreen` do obsługi `StatefulNavigationShell`, synchronizacja `AppSidebar` i `currentNavIndexProvider` z gałęziami shella | `lib/presentation/screens/main_navigation_screen.dart` |
| **Task 3** | Aktualizacja linków i przycisków w `DashboardScreen` do `context.go` | `lib/presentation/screens/dashboard/dashboard_screen.dart` |

---

## 3. Decisions & Adherence

- **D-01 (Path URL Strategy):** Brak hasha (`#`) w URL. Zgodne z regułami rewrite w `firebase.json`.
- **D-02 (Polskie ścieżki):** Trasy zdefiniowane po polsku: `/pulpit`, `/plan-lekcji`, `/oceny`, `/frekwencja`, `/wiadomosci`, `/logowanie`, `/polacz-librus`.
- **D-04 (Zapamiętywanie redirect):** Niezalogowany użytkownik wchodzący pod `/oceny` zostaje przekierowany do `/logowanie?redirect=%2Foceny`.
- **D-05 (StatefulShellRoute):** Stan widoków nie jest niszczony przy przełączaniu modułów.

---

## 4. Verification & Quality Gates

- `flutter analyze` — brak błędów i ostrzeżeń (0 issues).
- `flutter build web --release` — zakończony pomyślnie.
- Wdrożenie na Firebase Hosting: wersja aktywna pod `https://lepsza-szkola.web.app`.
