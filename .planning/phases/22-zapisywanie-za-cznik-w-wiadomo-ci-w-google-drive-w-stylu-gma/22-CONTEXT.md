# Phase 22: Zapisywanie załączników wiadomości w Google Drive w stylu Gmail - Context

**Gathered:** 2026-09-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Wdrożenie możliwości zapisywania załączników wiadomości z Librusa bezpośrednio na koncie Google Drive użytkownika na wzór mechanizmu znanego z Gmaila: dedykowana ikona „Zapisz na Dysku Google” obok ikony „Pobierz” na każdym kafelku załącznika, przycisk zbiorczy „Zapisz wszystkie na Dysku” przy wielu załącznikach, natychmiastowy zapis do wskazanego przez użytkownika folderu docelowego (z fallbackiem do głównego katalogu „Mój dysk”), możliwość szybkiego przeniesienia/zmiany folderu z poziomu komunikatu potwierdzenia oraz konfiguracji domyślnego folderu w Ustawieniach, a także trwałe zapisywanie statusu i linku `webViewLink` w Firestore wspólnie dla domowników (zmiana ikony na „Otwórz w Google Drive”).

</domain>

<decisions>
## Implementation Decisions

### Organizacja i wybór folderu na Google Drive
- **D-01:** Załączniki są zapisywane do wskazanego przez użytkownika folderu na Google Drive, a jeśli żaden folder nie został skonfigurowany — bezpośrednio w głównym katalogu „Mój dysk” (`root`).
- **D-02:** Wybór i zmiana folderu działają identycznie jak w Gmailu: kliknięcie „Zapisz na Dysku” wykonuje natychmiastowy zapis (do domyślnego folderu lub „Mój dysk”), a w dymku/komunikacie potwierdzenia pojawia się akcja **„Zmień folder / Przenieś”** pozwalająca wskazać lub utworzyć folder na Google Drive i ustawić go jako domyślny.
- **D-03:** W ekranie Ustawień aplikacji dostępna jest konfiguracja domyślnego folderu docelowego na Google Drive dla załączników szkolnych (wraz z możliwością wyboru/wpisania folderu lub przywrócenia zapisu w „Mój dysk”).

### Interakcja UI na kafelkach załączników (styl Gmail)
- **D-04:** Na każdym kafelku załącznika w widoku szczegółów wiadomości (`MessageThreadScreen`) widoczne są dwie osobne ikony akcji:
  1. **Pobierz na urządzenie** (`Icons.download_rounded`) — pobiera plik lokalnie przez `/api/downloadAttachment`.
  2. **Zapisz na Dysku Google** (`Icons.add_to_drive_rounded`) — przesyła załącznik na Google Drive.
- **D-05:** Gdy wiadomość zawiera 2 lub więcej załączników, w nagłówku sekcji załączników wyświetlany jest zbiorczy przycisk **„Zapisz wszystkie na Dysku”**, który przesyła wszystkie jeszcze niezapisane załączniki z tej wiadomości do docelowego folderu Google Drive.
- **D-06:** Podczas zapisywania na Google Drive na kafelku załącznika wyświetlany jest czytelny stan ładowania (spinner w miejscu ikony Drive).

### Trwałość stanu „Zapisano na Dysku” i współdzielenie w rodzinie
- **D-07:** Po pomyślnym zapisaniu załącznika na Google Drive informacja o zapisie (`driveFileId`, `webViewLink`, `folderId`, `folderName`, `savedAt`, `savedBy`) jest trwale zapisywana w Firestore przy danej wiadomości w dokumencie ucznia (`students/{studentId}`).
- **D-08:** Dla załączników posiadających zapisany status w Firestore ikona akcji Drive zmienia się na **„Otwórz w Google Drive”** (np. ikona `Icons.open_in_new_rounded` / `Icons.check_circle_outline` z etykietą lub podpowiedzią „Otwórz w Google Drive”), a jej kliknięcie otwiera bezpośrednio `webViewLink` zapisanego pliku w Google Drive. Status ten jest od razu widoczny dla wszystkich domowników korzystających z konta ucznia.

### Autoryzacja Google OAuth i przesyłanie pliku
- **D-09:** Dostęp do Google Drive wykorzystuje bezpieczny, nieinwazyjny zakres OAuth `https://www.googleapis.com/auth/drive.file` w `FirebaseAuthService` (dający aplikacji dostęp wyłącznie do plików i folderów utworzonych przez samą aplikację). Jeśli użytkownik nie ma aktywnego tokenu OAuth z zakresem `drive.file`, kliknięcie „Zapisz na Dysku” wywołuje popup autoryzacji Google (`signInWithPopup` / `reauthenticateWithPopup` z zakresem `drive.file`).
- **D-10:** Aby uniknąć ograniczeń CORS na domenie `sandbox.librus.pl` oraz podwójnego przesyłania dużych plików przez przeglądarkę, pobieranie strumienia binarnego załącznika z Librusa i wysyłka (`multipart/related` lub `resumable`) do Google Drive REST API v3 (lub przesłanie za pośrednictwem dedykowanego endpointu Cloud Function `/api/saveAttachmentToDrive`) odbywa się z użyciem tokenu OAuth użytkownika i automatyczną aktualizacją metadanych wiadomości w Firestore.

### the agent's Discretion
- Dokładny wygląd modala „Zmień folder / Przenieś” (lista folderów utworzonych przez aplikację + opcja utworzenia nowego folderu po nazwie + opcja „Mój dysk”).
- Sposób cachowania krótkotrwałego `accessToken` Google OAuth w pamięci sesji przeglądarki, aby przy zapisywaniu wielu załączników z rzędu nie otwierać popupu Google za każdym razem.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Dokumentacja projektu i Roadmapa
- `.planning/ROADMAP.md` §Phase 22 — cel fazy, kryteria sukcesu i zależności od Fazy 21.
- `.planning/quick/260928-ogq-parsowanie-wy-wietlanie-i-pobieranie-za-/260928-ogq-SUMMARY.md` — szczegóły działania pobierania załączników z Librusa (`/wiadomosci/pobierz_zalacznik/{msgId}/{attId}` -> `https://sandbox.librus.pl/GetFile/{token}/get`) oraz struktury `attachmentFiles` i `attachmentUrls`.

### Istniejąca implementacja wiadomości, autoryzacji i ustawień
- `functions/src/librus_client.js` — metody `_parseMessageAttachments($)` oraz `resolveAttachmentDownloadUrl(downloadPath)`.
- `functions/index.js` — endpointy `exports.getMessageDetails` oraz `exports.downloadAttachment`.
- `lib/core/auth/firebase_auth_service.dart` — logowanie Google (`GoogleAuthProvider`, `signInWithPopup`) i zarządzanie sesją Firebase Auth.
- `lib/domain/models/message_thread.dart` — modele `MessageItem` oraz `MessageThread` (pola `attachments`, `attachmentUrls`, `hasAttachments`).
- `lib/data/repositories/school_repository.dart` i `lib/data/repositories/firestore_school_repository.dart` — interfejs i implementacja operacji na wiadomościach i Firestore.
- `lib/presentation/screens/messages/message_thread_screen.dart` — obecny widok szczegółów wiadomości i kafelków załączników.
- `lib/presentation/screens/settings/settings_screen.dart` — ekran Ustawień, w którym znajdzie się konfiguracja domyślnego folderu Google Drive.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LibrusClient.resolveAttachmentDownloadUrl(downloadPath)` w `functions/src/librus_client.js`: rozwiązuje ścieżkę `/wiadomosci/pobierz_zalacznik/...` do bezpośredniego linku binarnego `https://sandbox.librus.pl/GetFile/{token}/get`.
- `FirebaseAuthService` w `lib/core/auth/firebase_auth_service.dart`: obsługuje `GoogleAuthProvider` na Web; można rozszerzyć o metodę `requestGoogleDriveAccessToken()` wykorzystującą scope `https://www.googleapis.com/auth/drive.file`.
- `openUrlInBrowser(String url)` w `lib/core/utils/url_launcher_stub.dart` / `url_launcher_web.dart`: otwiera zewnętrzne linki (np. `webViewLink` do pliku/folderu w Google Drive) w nowej karcie przeglądarki.

### Established Patterns
- Endpointy Cloud Functions wystawiane pod `/api/*` w `firebase.json` (np. `/api/messageDetails`, `/api/downloadAttachment`) i wywoływane z `FirestoreSchoolRepository`.
- Aktualizacja tablicy `messages` w dokumencie `students/{studentId}` w Firestore po stronie Cloud Functions i automatyczna reaktywna synchronizacja do UI Fluttera przez `StreamProvider`.

### Integration Points
- Nowy endpoint Cloud Function `/api/saveAttachmentToDrive` (oraz opcjonalnie `/api/moveDriveAttachment` / obsługa folderów Drive) w `functions/index.js` i `firebase.json`.
- Rozszerzenie `MessageItem` i `MessageThread` w `lib/domain/models/message_thread.dart` o mapę metadanych zapisanych załączników w Google Drive (np. `driveAttachments: Map<String, DriveAttachmentInfo>`).
- Sekcja załączników w `lib/presentation/screens/messages/message_thread_screen.dart` (lub wydzielonym w Fazie 21 widgecie szczegółów wiadomości).
- Sekcja integracji z Google Drive w `lib/presentation/screens/settings/settings_screen.dart`.

</code_context>

<specifics>
## Specific Ideas

- Dokładne odwzorowanie przepływu z Gmaila:
  1. Kliknięcie ikony „Zapisz na Dysku” na załączniku zapisuje plik od razu (do wybranego wcześniej domyślnego folderu lub do głównego folderu „Mój dysk”).
  2. Po zapisaniu pojawia się potwierdzenie (SnackBar / baner) z informacją, gdzie plik został zapisany (np. `Zapisano w: Mój dysk` lub `Zapisano w: Szkoła`) oraz przyciskiem **„Zmień folder / Przenieś”**.
  3. Kliknięcie „Zmień folder / Przenieś” pozwala wskazać docelowy folder (lub utworzyć nowy), przenosi właśnie zapisany plik do tego folderu i pozwala zapisać ten folder jako domyślny na przyszłość.
  4. Domyślny folder można też w każdej chwili zmienić w Ustawieniach aplikacji.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma*
*Context gathered: 2026-09-28*
