# Plan 13-02: Deep linking do zasobów: wątki wiadomości, plan lekcji z parametrem daty i filtry — Summary

**Phase:** 13 — dedykowane-url-i-routing-dla-podstron-i-zasob-w-deep-linking  
**Plan ID:** 13-02  
**Status:** Completed  
**Completed Date:** 2026-09-21  

---

## 1. Executive Summary

Plan 13-02 wdrożył zaawansowane mechanizmy głębokiego linkowania (deep linking) do konkretnych zasobów w EduSync:
1. **Wątki wiadomości (`/wiadomosci/:threadId`):**
   - Dodano podtrasę dla pojedynczego wątku z `parentNavigatorKey: rootNavigatorKey`.
   - Obsługuje zarówno szybkie otwieranie z listy wiadomości (z zachowaniem obiektu `extra: MessageThread`), jak i bezpośrednie wejście z zewnętrznego linku (np. wklejenie adresu URL w przeglądarce), gdzie wątek wyszukiwany jest asynchronicznie z dostawcy wiadomości ze wskaźnikiem ładowania lub komunikatem o braku wiadomości.
   - Zaktualizowano przycisk wstecz w `MessageThreadScreen`, aby obsługiwał `context.canPop() ? context.pop() : context.go('/wiadomosci')`.
2. **Plan lekcji z datą (`/plan-lekcji?data=YYYY-MM-DD`):**
   - Trasa `/plan-lekcji` parsuje query parameter `data`.
   - Automatycznie synchronizuje poniedziałek danego tygodnia (`selectedWeekMondayProvider`) oraz wybrany dzień (`selectedScheduleDayProvider`).
   - W sekcji "Nadchodzący Sprawdzian" na Pulpicie przycisk "Zobacz w terminarzu" otwiera plan dokładnie z parametrem daty sprawdzianu: `/plan-lekcji?data=YYYY-MM-DD`.
3. **Oceny i Frekwencja z query parametrami:**
   - Trasa `/oceny` wspiera parametr `?semestr=1` lub `?semestr=2` (`initialTerm` w `GradesScreen`).
   - Trasa `/frekwencja` wspiera parametr `?filtr=wszystkie`, `?filtr=do-usprawiedliwienia`, `?filtr=usprawiedliwione` (`initialFilter` w `AttendanceScreen`).
4. **Czysta nawigacja z innych ekranów:**
   - W `GradesScreen` przyciski "Kontakt z nauczycielem" przekierowują bezpośrednio do `/wiadomosci`.

---

## 2. Tasks Completed & Changes

| Task | Opis | Pliki |
|---|---|---|
| **Task 1** | Deep linking dla wątków wiadomości (`/wiadomosci/:threadId`), bezpieczny powrót przy wejściu z linku zewnętrznego | `lib/presentation/routes/app_router.dart`, `lib/presentation/screens/messages/message_thread_screen.dart`, `lib/presentation/screens/messages/messages_screen.dart` |
| **Task 2** | Deep linking dla terminarza/planu lekcji (`/plan-lekcji?data=YYYY-MM-DD`), aktualizacja linku ze sprawdzianu | `lib/presentation/routes/app_router.dart`, `lib/presentation/screens/dashboard/dashboard_screen.dart` |
| **Task 3** | Parametry filtrowania semestrów (`/oceny?semestr=...`) i frekwencji (`/frekwencja?filtr=...`) | `lib/presentation/routes/app_router.dart`, `lib/presentation/screens/grades/grades_screen.dart`, `lib/presentation/screens/attendance/attendance_screen.dart` |

---

## 3. Decisions & Adherence

- **D-03 (Deep linking do zasobów):** Adresy `/wiadomosci/:threadId` oraz `/plan-lekcji?data=YYYY-MM-DD` działają bezpośrednio i mogą być udostępniane.
- **Bezpieczny fallback powrotu:** Otwarcie bezpośredniego URL-a i kliknięcie strzałki wstecz w wątku wiadomości nie zamyka aplikacji, lecz cofa do `/wiadomosci`.

---

## 4. Verification & Quality Gates

- `flutter analyze` — 0 błędów, 0 ostrzeżeń.
- `flutter build web --release` — kompilacja zakończona sukcesem.
- Wdrożenie na Firebase Hosting: wersja produkcyjna opublikowana pod `https://lepsza-szkola.web.app`.
