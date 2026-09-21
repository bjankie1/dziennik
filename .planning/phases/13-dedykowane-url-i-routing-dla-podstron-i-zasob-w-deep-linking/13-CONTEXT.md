# Phase 13: Dedykowane URL i routing dla podstron i zasobów (deep linking) — Context

## User Decisions

- **D-01 (Format URL):** Czyste ścieżki HTML5 History API bez hasha (Path URL Strategy, np. `https://lepsza-szkola.web.app/plan-lekcji`). Firebase Hosting posiada już odpowiednie reguły rewrites (`"source": "**", "destination": "/index.html"`).
- **D-02 (Konwencja nazewnictwa tras):** Język polski, czytelne i intuicyjne ścieżki:
  - `/` -> przekierowanie na `/pulpit`
  - `/pulpit` -> Pulpit (DashboardScreen)
  - `/plan-lekcji` -> Plan lekcji (ScheduleScreen)
  - `/oceny` -> Panel ocen (GradesScreen)
  - `/frekwencja` -> Moduł frekwencji (AttendanceScreen)
  - `/wiadomosci` -> Moduł wiadomości (MessagesScreen)
  - `/logowanie` -> Ekran logowania (LoginScreen)
  - `/polacz-librus` -> Ekran łączenia z kontem Librus (LibrusConnectScreen)
- **D-03 (Deep linking do zasobów):**
  - `/wiadomosci/:threadId` -> bezpośrednie otwarcie wątku wiadomości (MessageThreadScreen) z możliwością powrotu do `/wiadomosci`.
  - `/plan-lekcji?data=YYYY-MM-DD` -> bezpośrednie ustawienie tygodnia i dnia w planie lekcji na podstawie przekazanej daty.
  - `/oceny?semestr=1` lub `semestr=2` -> opcjonalne ustawienie aktywnego semestru.
- **D-04 (Autoryzacja i ochrona tras):**
  - Gdy niezalogowany użytkownik wejdzie z bezpośredniego linku (np. `/plan-lekcji?data=...` lub `/wiadomosci/123`), system zapamiętuje docelowy URL (query param `?redirect=...`).
  - Po pomyślnej autoryzacji / autologinie użytkownik jest automatycznie przekierowywany do żądanej podstrony zamiast zawsze trafiać na pulpit.
- **D-05 (Integracja z interfejsem):**
  - Pasek boczny (`AppSidebar`), nagłówek (`AppDesktopHeader`), przyciski szybkiej nawigacji z pulpitu (np. "Pełny plan lekcji", "Zobacz wszystkie oceny", "Otwórz skrzynkę") oraz przyciski Wstecz/Dalej w przeglądarce są w 100% zsynchronizowane z URL.
  - Zastosowanie biblioteki `go_router` (oficjalny, rekomendowany standard Flutter dla deep linkingu i Web URL strategy) z pełnym wsparciem dla Riverpod.

## Canonical Refs
- `lib/presentation/screens/main_navigation_screen.dart` — główny kontener zakładek (obecnie przełączany indeksem 0..4)
- `lib/presentation/widgets/app_sidebar.dart` — nawigacja boczna
- `lib/presentation/screens/auth/auth_gate.dart` — bramka uwierzytelniania
- `firebase.json` — konfiguracja rewrites dla Firebase Hosting
