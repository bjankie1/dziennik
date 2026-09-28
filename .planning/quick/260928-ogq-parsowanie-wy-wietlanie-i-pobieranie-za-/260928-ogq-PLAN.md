---
phase: quick-260928-ogq
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
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
autonomous: true
requirements:
  - QUICK-260928-OGQ
must_haves:
  truths:
    - "Wiadomości posiadające sekcję 'Pliki:' w Librus Synergia (np. wiadomość 2027508 z plikami matura2027_wrzesien2026_R_U.pdf i matura2027_wrzesien2026_R_U.pptx) mają sparsowane nazwy i ścieżki pobierania załączników"
    - "FirestoreSchoolRepository przekazuje listę załączników oraz mapę ścieżek pobierania do obiektu MessageThread i MessageItem"
    - "Widok wątku wiadomości (MessageThreadScreen) wyświetla wszystkie załączniki z odpowiednią ikoną typu pliku (PDF, PPTX, DOCX itd.) i umożliwia ich pobranie jednym kliknięciem przez endpoint /api/downloadAttachment"
  artifacts:
    - path: "functions/src/librus_client.js"
      provides: "Parsowanie załączników w fetchMessages i fetchMessageDetails oraz resolveAttachmentDownloadUrl"
    - path: "functions/index.js"
      provides: "Endpoint Cloud Function downloadAttachment przekierowujący do pliku z sandbox.librus.pl oraz aktualizacja cache Firestore w getMessageDetails"
    - path: "lib/data/repositories/firestore_school_repository.dart"
      provides: "Mapowanie attachments i attachmentUrls w getMessages oraz dociąganie szczegółów wiadomości z załącznikami"
    - path: "lib/presentation/screens/messages/message_thread_screen.dart"
      provides: "Interaktywne kafelki załączników z obsługą pobierania i ikonami zależnymi od rozszerzenia"
---

<objective>
Naprawa brakujących załączników w wiadomościach z Librus Synergia (m.in. wiadomość `2027508` — „Informacje na temat egzaminu maturalnego" zawierająca pliki `matura2027_wrzesien2026_R_U.pdf` oraz `matura2027_wrzesien2026_R_U.pptx`), włącznie z ich parsowaniem po stronie backendu, przekazywaniem przez `FirestoreSchoolRepository`, wyświetlaniem w UI oraz bezpośrednim pobieraniem po kliknięciu.
</objective>

<tasks>

<task type="auto">
  <name>Task 1: Parsowanie załączników w LibrusClient i endpoint pobierania w Cloud Functions</name>
  <files>
    functions/src/librus_client.js
    functions/index.js
    firebase.json
  </files>
  <action>
    1. W `functions/src/librus_client.js`:
       - Dodaj metodę pomocniczą `_parseMessageAttachments($, msgId)`, która wyszukuje wiersze tabeli `Pliki:` zawierające `otworz_w_nowym_oknie("/wiadomosci/pobierz_zalacznik/...")` (lub linki `pobierz_zalacznik`) i zwraca tablicę obiektów `{ name, path }`.
       - W `fetchMessages()` wykrywaj ikonę załącznika w kolumnie statusu (`img[src*="attachment"], img.existing-msg-files-icon`) jako `hasAttachments`. Dla najnowszych 10 wiadomości oraz wszystkich wiadomości posiadających `hasAttachments` pobieraj szczegóły z `m.librusUrl`, zapisując `m.attachments` (lista nazw plików) oraz `m.attachmentFiles` (`[{ name, path }]`).
       - W `fetchMessageDetails(msgId, librusUrl)` parsuj załączniki przez `_parseMessageAttachments($, msgId)` i zwracaj `attachments` oraz `attachmentFiles`.
       - Dodaj metodę `resolveAttachmentDownloadUrl(downloadPath)`, która wykonuje zapytanie do `https://synergia.librus.pl${downloadPath}` i odczytuje docelowy URL z przekierowania `https://sandbox.librus.pl/GetFile/...`, doklejając `/get` zwracające właściwy plik binarny.
    2. W `functions/index.js`:
       - W `getMessageDetails` zapisuj `attachments` i `attachmentFiles` do zcache'owanego dokumentu `students/{login}` w Firestore.
       - Dodaj funkcję HTTP `exports.downloadAttachment`, która przyjmuje parametr `path` (np. `/wiadomosci/pobierz_zalacznik/2027508/12466101`), rozwiązuje jednorazowy link `sandbox.librus.pl/GetFile/.../get` przez `LibrusClient` i wykonuje przekierowanie `302` do pobieranego pliku.
    3. W `firebase.json`:
       - Dodaj rewrite `/api/downloadAttachment` -> `downloadAttachment` (`europe-west3`).
  </action>
  <verify>
    Test w Node.js potwierdzający, że `fetchMessageDetails('2027508')` zwraca oba załączniki (`matura2027_wrzesien2026_R_U.pdf`, `matura2027_wrzesien2026_R_U.pptx`), a `resolveAttachmentDownloadUrl` zwraca działający URL `https://sandbox.librus.pl/GetFile/.../get`.
  </verify>
  <done>
    Backend Cloud Functions poprawnie wyciąga listę plików z wiadomości Librusa, aktualizuje cache w Firestore i wystawia endpoint `/api/downloadAttachment`.
  </done>
</task>

<task type="auto">
  <name>Task 2: Obsługa załączników w modelu, repozytorium i interfejsie Flutter</name>
  <files>
    lib/domain/models/message_thread.dart
    lib/data/repositories/school_repository.dart
    lib/data/repositories/mock_school_repository.dart
    lib/data/repositories/firestore_school_repository.dart
    lib/presentation/screens/messages/message_thread_screen.dart
    lib/presentation/screens/messages/messages_screen.dart
    lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart
  </files>
  <action>
    1. W `lib/domain/models/message_thread.dart`:
       - Dodaj pole `final Map<String, String> attachmentUrls;` (domyślnie `const {}`) oraz flagę `final bool hasAttachments;` do `MessageItem` i `MessageThread` wraz z obsługą w konstruktorze i `copyWith`.
    2. W `lib/data/repositories/firestore_school_repository.dart`:
       - W `getMessages()` odczytuj `item['attachments']`, `item['attachmentFiles']` oraz `item['hasAttachments']`, budując listę `attachments` (`List<String>`) i mapę `attachmentUrls` (`Map<String, String>`) i przekazując je do `MessageThread(...)`.
       - Dodaj metodę `getMessageDetails(String msgId, {String? url})` w `SchoolRepository`, `MockSchoolRepository` i `FirestoreSchoolRepository`, która zwraca pełne dane wiadomości (`body`, `attachments`, `attachmentUrls`) z `/api/messageDetails` i aktualizuje cache w pamięci.
    3. W `lib/presentation/screens/messages/message_thread_screen.dart`:
       - W `_fetchBodyIfNeeded()` dociągaj szczegóły wiadomości przez `getMessageDetails` również wtedy, gdy wiadomość ma `hasAttachments == true` (lub treść wskazuje na załącznik/prezentację/plik), a lista `attachments` lub `attachmentUrls` jest pusta.
       - W `_buildExpandedMessage` zamień statyczne kafelki załączników na klikalne komponenty `InkWell` z ikoną dopasowaną do rozszerzenia pliku (`.pdf`, `.pptx`/`.ppt`, `.docx`/`.doc`, `.xlsx`/`.xls`, obrazy), nazwą pliku i ikoną pobierania `Icons.download_rounded`, które otwierają `/api/downloadAttachment?path=...` w przeglądarce (`openUrlInBrowser`).
    4. W `lib/presentation/screens/messages/messages_screen.dart` oraz `lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart`:
       - Popraw odmianę liczby załączników (`1 załącznik`, `2 załączniki`, `5 załączników`) oraz wyświetlaj rzeczywistą nazwę załącznika na karcie dashboardu.
  </action>
  <verify>
    `flutter analyze` oraz `flutter test` przechodzą bez błędów.
  </verify>
  <done>
    Załączniki są widoczne i klikalne na ekranie wiadomości `https://lepsza-szkola.web.app/wiadomosci/2027508`, a lista wiadomości i dashboard pokazują poprawną informację o załącznikach.
  </done>
</task>

</tasks>
