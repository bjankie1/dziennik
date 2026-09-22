# Phase 14: Dostęp ucznia (rola student vs parent) i współdzielony cache danych — Podsumowanie Fazy

**Faza:** 14  
**Milestone:** v3.0 (Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia)  
**Status:** Zakończona sukcesem (COMPLETED)  
**Data ukończenia:** 2026-09-22  

---

## 1. Cel i zrealizowane wymagania

Faza 14 zrealizowała pełną obsługę niezależnego konta ucznia (Oskar) obok konta rodzica, optymalizując ruch sieciowy do Librus Synergia i zabezpieczając uprawnienia e-dziennika:

- **REQ-ROLE-01: Dostęp dla Oskara (rola `student` vs `parent`):**
  - Wprowadzono model `UserRole` (`parent`, `student`) z trwałością w `SharedPreferences` i profilu Firestore.
  - Wyraźne oznaczenie roli w interfejsie (`AppDesktopHeader` z badge'em `🎓 Uczeń` / `Rodzic` oraz szczegółowy panel roli w arkuszu profilu).
  - Wygodny selektor roli `SegmentedButton<UserRole>` na ekranie łączenia konta (`LibrusConnectScreen`).
  - Wysyłanie wiadomości z poziomu konta ucznia korzysta z odrębnych ciasteczek sesyjnych w `librus_sessions/{studentLogin}`, gwarantując nauczycielom poprawną tożsamość nadawcy (*Oskar Jankiewicz*).

- **REQ-ROLE-02: Uprawnienia i workflow e-usprawiedliwień:**
  - Całkowicie wyeliminowano pole PIN i możliwość bezpośredniego wysyłania usprawiedliwień przez ucznia.
  - Wprowadzono dwustronny obieg: uczeń składa prośbę o usprawiedliwienie (`StudentJustificationModal`), która trafia do kolekcji `justification_requests` ze statusem `pending_parent_approval`.
  - Rodzic otrzymuje powiadomienie na Pulpicie (kafelek w siatce Bento i baner na widoku mobilnym) oraz w module Frekwencji, po czym zatwierdza wniosek kodem PIN `1234` (`ParentApprovalModal`), co wyzwala oficjalne e-usprawiedliwienie w Librusie.

- **REQ-ROLE-03: Współdzielony cache danych (Single Source of Truth):**
  - Wszystkie zapytania o oceny, terminarz i plan lekcji dla ucznia czytają z dokumentu rodzica `students/{primaryLogin}`.
  - Usługa synchronizacji w Cloud Functions (`sync_service.js`) rygorystycznie blokuje scraping dla kont o roli `student`, eliminując dublowanie zapytań do serwerów szkoły (T-14-02).

---

## 2. Zrealizowane plany wykonawcze

1. **Plan 14-01 (Wave 1):**
   - Model `UserRole`, `AppUser`, provider `AppUserNotifier`.
   - Backend `saveConnection` i `getConnection` z polami ról i identyfikatorów.
   - Współdzielenie cache w `FirestoreSchoolRepository` i `sync_service.js`.
   - Zestawy testów: `user_roles.test.js`, `shared_cache.test.js`.

2. **Plan 14-02 (Wave 2):**
   - Model `JustificationRequest` i maszyna stanów (`pending_parent_approval` -> `approved` / `rejected`).
   - Endpointy `createJustificationRequest`, `reviewJustificationRequest`, `getJustificationRequests`.
   - Modale UI: `StudentJustificationModal` oraz `ParentApprovalModal` (autoryzacja PIN `1234`).
   - Integracja w `AttendanceScreen` i `DashboardScreen`.
   - Zestaw testów: `justification_requests.test.js`.

3. **Plan 14-03 (Wave 3):**
   - Pigułki i badge ról w `AppDesktopHeader` i `main_navigation_screen.dart`.
   - Selektor `SegmentedButton<UserRole>` w `LibrusConnectScreen`.
   - Odizolowana sesja ucznia i atrybucja tożsamości w `sendMessage` (`message_service.js`).
   - Zestaw testów: `student_messages.test.js`.
   - Podpisana strategia walidacji `14-VALIDATION.md`.

---

## 3. Metryki jakości i testy

- **Testy jednostkowe backendu (`functions/`):** 51/51 testów zaliczonych (19 zestawów testowych, czas wykonania ~210ms).
- **Analiza statyczna Flutter:** `flutter analyze` — 0 błędów, 0 ostrzeżeń.
- **Wszystkie commity:** atomowe, zgodne z konwencją konwencjonalnych commitów.

---

## 4. Następny krok

Przejście do **Fazy 15: Moduł zadań (Smart To-Do) i widżet na Pulpicie** (`REQ-TODO-01`, `REQ-TODO-02`).
