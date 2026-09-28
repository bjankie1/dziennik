---
phase: quick-260928-ogq
plan: 01
subsystem: messages
tags: [librus, attachments, messages, cloud-functions, flutter-web]
requires: []
provides:
  - Parsowanie sekcji "Pliki:" w wiadomościach Librus Synergia (_parseMessageAttachments)
  - Endpoint Cloud Function /api/downloadAttachment rozwiązujący jednorazowe linki sandbox.librus.pl/GetFile/.../get
  - Mapowanie attachments, attachmentUrls i hasAttachments w FirestoreSchoolRepository
  - Klikalne kafelki załączników z ikonami wg typu pliku (.pdf, .pptx, .docx, .xlsx) w MessageThreadScreen
affects:
  - functions/src/librus_client.js
  - functions/index.js
  - firebase.json
  - lib/domain/models/message_thread.dart
  - lib/data/repositories/firestore_school_repository.dart
  - lib/presentation/screens/messages/message_thread_screen.dart
  - lib/presentation/screens/messages/messages_screen.dart
  - lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart
tech-stack:
  added: []
  patterns:
    - "Rozwiązywanie 302 redirect z /wiadomosci/pobierz_zalacznik/{msgId}/{attId} do podpisanych tokenem linków https://sandbox.librus.pl/GetFile/{token}/get"
key-files:
  created:
    - test/message_attachments_test.dart
  modified:
    - functions/src/librus_client.js
    - functions/index.js
    - firebase.json
    - lib/domain/models/message_thread.dart
    - lib/data/repositories/school_repository.dart
    - lib/data/repositories/mock_school_repository.dart
    - lib/data/repositories/firestore_school_repository.dart
    - lib/presentation/screens/messages/message_thread_screen.dart
    - lib/presentation/screens/messages/messages_screen.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart
key-decisions:
  - "Przekierowanie 302 z /api/downloadAttachment bezpośrednio do https://sandbox.librus.pl/GetFile/{token}/get, co pozwala na natywne pobranie dużych plików (np. 3.5 MB PDF/PPTX) bez buforowania w pamięci Cloud Function i bez potrzeby posiadania ciasteczek Librusa w przeglądarce użytkownika."
requirements-completed:
  - QUICK-260928-OGQ
duration: 15min
completed: 2026-09-28
status: complete
---

# Quick Task 260928-ogq: Parsowanie, wyświetlanie i pobieranie załączników wiadomości z Librus Synergia

## Przyczyna błędu (Root Cause)
Wiadomość `2027508` („Informacje na temat egzaminu maturalnego" od wychowawcy Łukasza Soboty) w Librus Synergia posiada pod treścią wiadomości osobną tabelę HTML `<b>Pliki:</b>` z dwoma załącznikami:
- `matura2027_wrzesien2026_R_U.pdf` (`/wiadomosci/pobierz_zalacznik/2027508/12466101`)
- `matura2027_wrzesien2026_R_U.pptx` (`/wiadomosci/pobierz_zalacznik/2027508/12466102`)

Załączniki nie wyświetlały się w aplikacji z trzech powodów:
1. **Brak parsowania w `LibrusClient` (`functions/src/librus_client.js`):** Zarówno `fetchMessages()`, jak i `fetchMessageDetails()` pobierały wyłącznie tekst z `div.container-message-content`, ignorując tabelę `Pliki:` oraz wywołania `otworz_w_nowym_oknie("/wiadomosci/pobierz_zalacznik/...")`.
2. **Brak przekazywania w `FirestoreSchoolRepository` (`lib/data/repositories/firestore_school_repository.dart`):** Metoda `getMessages()` tworzyła obiekty `MessageThread` bez przekazywania parametru `attachments`.
3. **Brak mechanizmu pobierania plików z Librusa:** Linki `/wiadomosci/pobierz_zalacznik/...` wymagają sesji Librusa i zwracają przekierowanie `302` do jednorazowego adresu `https://sandbox.librus.pl/GetFile/{token}`, gdzie właściwy plik binarny jest serwowany pod sufiksem `/get`.

## Wprowadzone zmiany
- **`functions/src/librus_client.js`**:
  - Dodano `_parseMessageAttachments($)`, które wyciąga nazwy plików i ścieżki `/wiadomosci/pobierz_zalacznik/{msgId}/{attId}` z widoku szczegółów wiadomości.
  - Zaktualizowano `fetchMessages()` oraz `fetchMessageDetails()`, aby zapisywały `hasAttachments`, `attachments` (lista nazw) oraz `attachmentFiles` (`[{ name, path }]`).
  - Dodano `resolveAttachmentDownloadUrl(downloadPath)`, które odpytuje Librusa o przekierowanie do `sandbox.librus.pl/GetFile/...` i zwraca bezpośredni link `/get`.
- **`functions/index.js` & `firebase.json`**:
  - Dodano endpoint Cloud Function `downloadAttachment` (`/api/downloadAttachment`), który autoryzuje sesję w Librusie i przekierowuje przeglądarkę (`302`) bezpośrednio do pobrania pliku z `sandbox.librus.pl`.
  - Zaktualizowano `getMessageDetails`, aby zapisywało sparsowane załączniki w cache Firestore (`students/{login}.messages`).
- **Warstwa Flutter (`message_thread.dart`, `firestore_school_repository.dart`, `message_thread_screen.dart`, `messages_screen.dart`, `dashboard_messages_column.dart`)**:
  - Rozszerzono `MessageThread` i `MessageItem` o `attachmentUrls` i `hasAttachments` oraz dodano `getMessageDetails()` w `SchoolRepository`.
  - W `MessageThreadScreen` zastąpiono statyczne etykiety interaktywnymi przyciskami pobierania z ikonami dopasowanymi do formatu pliku (`.pdf`, `.pptx`, `.docx`, `.xlsx`, obrazy, archiwa) oraz automatycznym dociąganiem szczegółów załączników.
  - Dodano test widgetowy `test/message_attachments_test.dart`.
