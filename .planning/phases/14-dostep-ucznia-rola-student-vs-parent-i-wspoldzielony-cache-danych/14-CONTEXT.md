# Phase 14: Dostęp ucznia (rola student vs parent) i współdzielony cache danych — Context

**Gathered:** 2026-09-22  
**Status:** Ready for planning  

<domain>
## Phase Boundary

Faza 14 wdraża wieloużytkownikowy model dostępu rodzinnego w EduSync:
1. **Tożsamość i logowanie ucznia:** Umożliwienie Oskarowi (uczniowi) logowania kontem Google z powiązaniem do jego własnych poświadczeń Librus Synergia (konto ucznia).
2. **Separacja ról (`student` vs `parent`):** Rola `student` gwarantuje wgląd w oceny, plan lekcji, terminarz i zadania, lecz blokuje bezpośrednie składanie e-usprawiedliwień szkolnych i zarządzanie PIN-em rodzica.
3. **Obieg „Prośba o usprawiedliwienie” (Student Justification Request):** Uczeń może zaznaczyć nieobecności, dodać własne wyjaśnienie i przesłać prośbę do rodzica. Rodzic otrzymuje powiadomienie na Pulpicie i zatwierdza wniosek kodem PIN.
4. **Współdzielony cache danych w Firestore:** Współdzielenie danych klasowych (plan lekcji, zastępstwa, terminarz) w Firestore bez dublowania odpytywania serwerów Librus.
5. **Autentyczne wiadomości od ucznia:** Wiadomości pisane przez Oskara wysyłane są z sesji jego konta Librus ucznia, dzięki czemu nauczyciele widzą go jako nadawcę.

</domain>

<decisions>
## Implementation Decisions

### 1. Tożsamość i autoryzacja konta ucznia
- **D-01 (Konto Librus ucznia):** Oskar posiada niezależny login i hasło ucznia w Librus Synergia. Po zalogowaniu kontem Google paruje swoje konto Librus ucznia, dzięki czemu sesja wysyłania wiadomości reprezentuje faktycznie ucznia, a nauczyciele widzą nadawcę: *Oskar Jankiewicz*.
- **D-02 (Separacja ról w modelu AppUser):** Wprowadzenie enumeratora `UserRole { parent, student }` w Firestore (`users/{uid}`) oraz modelu `AppUser` we Flutterze. Rola ucznia jest automatycznie oznaczana w nagłówku aplikacji dedykowanym badge'em „Uczeń”.

### 2. Uprawnienia i obieg e-usprawiedliwień
- **D-03 (Zakres uprawnień ucznia we Frekwencji):** Uczeń widzi pełne statystyki frekwencji, kołowy wskaźnik obecności i listę nieobecności. Zamiast przycisku „Zgłoś e-usprawiedliwienie (PIN)” uczeń ma przycisk **„Poproś rodzica o usprawiedliwienie”**.
- **D-04 (Obieg prośby o usprawiedliwienie):**
  - Uczeń zaznacza opuszczone godziny, podaje powód (np. „Wizyta u ortodonty”) i wysyła wniosek. W Firestore tworzy się dokument prośby w podkolekcji `justification_requests` ze statusem `pending_parent_approval`.
  - Na koncie rodzica (na Pulpicie w Bento Grid oraz w module Frekwencji) pojawia się powiadomienie: *„Oskar prosi o usprawiedliwienie (X godzin • powód)”*.
  - Rodzic może jednym kliknięciem przejrzeć prośbę, wprowadzić swój 4-cyfrowy PIN rodzica i zatwierdzić — Cloud Function natychmiast wysyła oficjalne e-usprawiedliwienie rodzica do Librusa.

### 3. Zarządzanie cache'em i zasobami
- **D-05 (Single Source of Truth dla danych klasy):** Dane planu lekcji, zastępstw, szczęśliwego numerka i terminarza są wspólne dla profilu ucznia/klasy w `students/{familyOrClassId}`. Odpytywanie w tle realizowane jest centralnie, eliminując podwójny scraping Librusa.
- **D-06 (Wspólna lista zadań To-Do):** Zarówno rodzic, jak i uczeń mają dostęp do tej samej kolekcji zadań szkolnych – obaj widzą ten sam postęp i mogą odhaczać zadania.

</decisions>

<canonical_refs>
## Canonical References

- `lib/presentation/providers/auth_providers.dart` — Model `AppUser`, `appUserProvider`, obsługa sesji.
- `lib/data/services/librus_connection_service.dart` — Połączenie z Firestore (`getConnection`, `saveConnection`).
- `functions/index.js` — Endpoints `saveConnection`, `getConnection`, obsługa ról użytkownika.
- `lib/presentation/screens/attendance/attendance_screen.dart` — Moduł frekwencji i formularz usprawiedliwień.
- `lib/presentation/screens/attendance/justification_modal.dart` — Modal usprawiedliwiania i weryfikacji PIN.
- `lib/presentation/screens/dashboard/dashboard_screen.dart` — Bento Grid i widżet powiadomień rodzica.
- `lib/presentation/widgets/app_desktop_header.dart` — Prezentacja profilu i badge roli użytkownika.

</canonical_refs>
