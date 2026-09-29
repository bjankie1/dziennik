# Phase 22: Zapisywanie załączników wiadomości w Google Drive w stylu Gmail - Research

**Researched:** 2026-09-28
**Domain:** Google Drive REST API v3 Integration, Firebase Google OAuth (`drive.file` scope), Cloud Functions Binary Stream Relay & Firestore Shared Family State
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Organizacja i wybór folderu na Google Drive
- **D-01:** Załączniki są zapisywane do wskazanego przez użytkownika folderu na Google Drive, a jeśli żaden folder nie został skonfigurowany — bezpośrednio w głównym katalogu „Mój dysk” (`root`).
- **D-02:** Wybór i zmiana folderu działają identycznie jak w Gmailu: kliknięcie „Zapisz na Dysku” wykonuje natychmiastowy zapis (do domyślnego folderu lub „Mój dysk”), a w dymku/komunikacie potwierdzenia pojawia się akcja **„Zmień folder / Przenieś”** pozwalająca wskazać lub utworzyć folder na Google Drive i ustawić go jako domyślny.
- **D-03:** W ekranie Ustawień aplikacji dostępna jest konfiguracja domyślnego folderu docelowego na Google Drive dla załączników szkolnych (wraz z możliwością wyboru/wpisania folderu lub przywrócenia zapisu w „Mój dysk”).

#### Interakcja UI na kafelkach załączników (styl Gmail)
- **D-04:** Na każdym kafelku załącznika w widoku szczegółów wiadomości (`MessageThreadScreen`) widoczne są dwie osobne ikony akcji:
  1. **Pobierz na urządzenie** (`Icons.download_rounded`) — pobiera plik lokalnie przez `/api/downloadAttachment`.
  2. **Zapisz na Dysku Google** (`Icons.add_to_drive_rounded`) — przesyła załącznik na Google Drive.
- **D-05:** Gdy wiadomość zawiera 2 lub więcej załączników, w nagłówku sekcji załączników wyświetlany jest zbiorczy przycisk **„Zapisz wszystkie na Dysku”**, który przesyła wszystkie jeszcze niezapisane załączniki z tej wiadomości do docelowego folderu Google Drive.
- **D-06:** Podczas zapisywania na Google Drive na kafelku załącznika wyświetlany jest czytelny stan ładowania (spinner w miejscu ikony Drive).

#### Trwałość stanu „Zapisano na Dysku” i współdzielenie w rodzinie
- **D-07:** Po pomyślnym zapisaniu załącznika na Google Drive informacja o zapisie (`driveFileId`, `webViewLink`, `folderId`, `folderName`, `savedAt`, `savedBy`) jest trwale zapisywana w Firestore przy danej wiadomości w dokumencie ucznia (`students/{studentId}`).
- **D-08:** Dla załączników posiadających zapisany status w Firestore ikona akcji Drive zmienia się na **„Otwórz w Google Drive”** (np. ikona `Icons.open_in_new_rounded` / `Icons.check_circle_outline` z etykietą lub podpowiedzią „Otwórz w Google Drive”), a jej kliknięcie otwiera bezpośrednio `webViewLink` zapisanego pliku w Google Drive. Status ten jest od razu widoczny dla wszystkich domowników korzystających z konta ucznia.

#### Autoryzacja Google OAuth i przesyłanie pliku
- **D-09:** Dostęp do Google Drive wykorzystuje bezpieczny, nieinwazyjny zakres OAuth `https://www.googleapis.com/auth/drive.file` w `FirebaseAuthService` (dający aplikacji dostęp wyłącznie do plików i folderów utworzonych przez samą aplikację). Jeśli użytkownik nie ma aktywnego tokenu OAuth z zakresem `drive.file`, kliknięcie „Zapisz na Dysku” wywołuje popup autoryzacji Google (`signInWithPopup` / `reauthenticateWithPopup` z zakresem `drive.file`).
- **D-10:** Aby uniknąć ograniczeń CORS na domenie `sandbox.librus.pl` oraz podwójnego przesyłania dużych plików przez przeglądarkę, pobieranie strumienia binarnego załącznika z Librusa i wysyłka (`multipart/related` lub `resumable`) do Google Drive REST API v3 (lub przesłanie za pośrednictwem dedykowanego endpointu Cloud Function `/api/saveAttachmentToDrive`) odbywa się z użyciem tokenu OAuth użytkownika i automatyczną aktualizacją metadanych wiadomości w Firestore.

### the agent's Discretion
- Dokładny wygląd modala „Zmień folder / Przenieś” (lista folderów utworzonych przez aplikację + opcja utworzenia nowego folderu po nazwie + opcja „Mój dysk”).
- Sposób cachowania krótkotrwałego `accessToken` Google OAuth w pamięci sesji przeglądarki, aby przy zapisywaniu wielu załączników z rzędu nie otwierać popupu Google za każdym razem.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-DRIVE-01 | Zapisywanie pojedynczych załączników oraz „Zapisz wszystkie na Dysku” bezpośrednio na Google Drive użytkownika (scope `drive.file`) w stylu Gmaila z natychmiastowym zapisem do wybranego folderu lub „Mój dysk” oraz opcją „Zmień folder / Przenieś”. | Supported by `FirebaseAuthService.requestGoogleDriveAccessToken()` (`GoogleAuthProvider` + `OAuthCredential.accessToken`), Cloud Function `/api/saveAttachmentToDrive` & `/api/driveFolder`, and `DriveFolderPickerModal`. |
| REQ-DRIVE-02 | Trwałe zapisywanie metadanych zapisanych załączników (`driveFileId`, `webViewLink`, `folderId`, `folderName`, `savedAt`, `savedBy`) w Firestore (`students/{studentId}.messages`) ze zmianą akcji na „Otwórz w Google Drive” oraz zachowaniem stanu między cyklami synchronizacji Librusa. | Supported by `DriveAttachmentInfo` domain model on `MessageItem`/`MessageThread`, Firestore persistence in `saveAttachmentToDrive` / `moveDriveAttachment`, and preservation in `mergeAndIndexMessages` (`functions/src/sync_service.js`). |
</phase_requirements>

---

## Summary

Phase 22 implements Gmail-style one-click saving of Librus Synergia message attachments to the user's Google Drive (`Icons.add_to_drive_rounded` alongside `Icons.download_rounded` on each attachment chip, plus a bulk „Zapisz wszystkie na Dysku” button when a message has 2 or more attachments). Because Librus serves attachments from `https://sandbox.librus.pl/GetFile/{token}/get` without CORS headers for browser `fetch()` calls, downloading the binary file and uploading it to Google Drive REST API v3 is executed server-side in a dedicated Firebase Cloud Function (`/api/saveAttachmentToDrive`) using the user's short-lived Google OAuth 2.0 `accessToken` (scope `https://www.googleapis.com/auth/drive.file`).

When the user clicks „Zapisz na Dysku”, the attachment is immediately uploaded to their configured default Drive folder (or directly to „Mój dysk” / `root` if no default folder is set, per **D-01** & **D-02**). Upon completion, a floating `SnackBar` confirms the destination (`Zapisano w: Mój dysk` or `Zapisano w: {folderName}`) and provides a **„Zmień folder / Przenieś”** action (or **„Otwórz”**). Clicking „Zmień folder / Przenieś” opens a `DriveFolderPickerModal` that lists folders created by the app on Google Drive, allows creating a new folder, moves the just-saved file(s) via Google Drive REST API v3 `PATCH /drive/v3/files/{fileId}?addParents=...&removeParents=...`, and optionally saves the chosen folder as the default for future uploads (also accessible anytime from the Profile/Settings sheet, per **D-03**).

Crucially, the saved state (`driveAttachments[attachmentName] = { driveFileId, webViewLink, folderId, folderName, savedAt, savedBy }`) is persisted on the message object inside `students/{studentId}.messages` in Firestore (**D-07**) and preserved across background Librus sync cycles in `mergeAndIndexMessages` (`functions/src/sync_service.js`). Once saved, all family members (Parent & Student) immediately see the „Otwórz w Google Drive” action (`Icons.open_in_new_rounded` / `Icons.cloud_done_rounded`) which opens `webViewLink` in a new browser tab (**D-08**).

**Primary recommendation:** Implement a pure Node.js helper module `functions/src/drive_service.js` backed by `axios` and Google Drive REST API v3 (`multipart/related` upload + folder list/create/move) exposed via Cloud Functions `/api/saveAttachmentToDrive` and `/api/driveFolder`, paired with in-memory OAuth `accessToken` caching in `FirebaseAuthService` (`lib/core/auth/firebase_auth_service.dart`).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Google OAuth 2.0 popup & `accessToken` acquisition (`drive.file` scope) | Browser / Client (`FirebaseAuthService`) | — | Must run in browser user gesture context via Firebase Auth Web popup (`signInWithPopup` / `reauthenticateWithPopup`) to obtain user's OAuth `accessToken`. |
| Librus attachment resolution & binary stream download | API / Backend (`functions/src/librus_client.js`) | — | Requires authenticated Librus session cookies and bypasses browser CORS restrictions on `sandbox.librus.pl/GetFile/{token}/get`. |
| Google Drive REST API v3 `multipart/related` upload & folder move/create | API / Backend (`functions/src/drive_service.js`) | Browser / Client | Cloud Function streams binary buffer from Librus directly to `googleapis.com/upload/drive/v3/files` in a single server-to-server hop and atomically updates Firestore. |
| Persistent attachment Drive state (`driveAttachments`) & default folder config | Database / Storage (`Firestore students/{studentId}`) | Browser / Client (`SharedPreferences`) | Shared family state (`Parent` + `Student`) requires Single Source of Truth in `students/{studentId}.messages` and `driveDefaultFolderId`/`driveDefaultFolderName`. |
| Gmail-style attachment tile UI, loading spinner, SnackBar & Folder Picker modal | Browser / Client (`MessageThreadScreen` / `DriveFolderPickerModal`) | — | Reactive UI rendering, per-attachment loading states, and folder selection dialog. |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `firebase_auth` | `6.7.0` `[VERIFIED: pubspec.lock:204-211]` | Google OAuth 2.0 popup with `GoogleAuthProvider.addScope('https://www.googleapis.com/auth/drive.file')` and `OAuthCredential.accessToken` extraction | Already installed in project; provides `OAuthCredential.accessToken` directly without needing `google_sign_in` or `googleapis_auth`. |
| `axios` | `^1.7.9` `[VERIFIED: functions/package.json:19]` | Binary `arraybuffer` download from `sandbox.librus.pl` and `multipart/related` / JSON requests to Google Drive REST API v3 | Already installed in `functions/`; supports raw `Buffer` bodies and custom `Multipart/related` headers natively. |
| `cloud_firestore` | `6.10.0` `[VERIFIED: pubspec.lock]` | Shared family persistence of `driveAttachments` on `students/{studentId}.messages` and default Drive folder preference | Already installed; powers Single Source of Truth for Parent and Student accounts. |
| `http` | `^1.6.0` `[VERIFIED: pubspec.yaml:39]` | Client calls to `/api/saveAttachmentToDrive` and `/api/driveFolder` | Already installed and used across `FirestoreSchoolRepository`. |
| `shared_preferences` | `^2.5.5` `[VERIFIED: pubspec.yaml:41]` | Fast local cache of `driveDefaultFolderId` and `driveDefaultFolderName` | Already installed and injected via `sharedPreferencesProvider`. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Google Drive REST API v3 | `v3` `[CITED: developers.google.com/drive/api/reference/rest/v3]` | Direct HTTPS endpoints for `multipart/related` upload, folder creation, folder listing, and moving file parents | All Google Drive operations from Cloud Functions using `Authorization: Bearer ${accessToken}`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct REST API v3 via `axios` in Cloud Functions | `googleapis` npm package (~180 MB unpacked) | `googleapis` bloats Cloud Functions cold start and bundle size for 4 simple REST calls (`POST upload/drive/v3/files`, `GET drive/v3/files`, `POST drive/v3/files`, `PATCH drive/v3/files/{id}`). Direct REST with `axios` adds 0 dependencies. |
| `firebase_auth` `GoogleAuthProvider` | `google_sign_in` + `googleapis` Dart packages | Adding `google_sign_in` introduces duplicate auth state alongside `FirebaseAuth.instance`. `FirebaseAuth` on Web already returns `OAuthCredential.accessToken` when `GoogleAuthProvider` is invoked with `addScope`. |

**Installation:**
No new npm or pub packages are required (`0` external packages added).

---

## Package Legitimacy Audit

No new external packages are installed in this phase. Existing dependencies in `pubspec.yaml` (`firebase_auth: ^6.7.0`, `http: ^1.6.0`, `cloud_firestore: ^6.10.0`, `shared_preferences: ^2.5.5`) and `functions/package.json` (`axios: ^1.7.9`, `firebase-admin: ^12.0.0`, `firebase-functions: ^5.0.0`) cover 100% of requirements `[VERIFIED: pubspec.yaml:30-50, functions/package.json:16-23]`.

---

## Architecture Patterns

### System Architecture Diagram

```
[User clicks "Zapisz na Dysku" (single) or "Zapisz wszystkie na Dysku" (bulk)]
       │
       ▼
[FirebaseAuthService.requestGoogleDriveAccessToken()]
       ├── Cached token valid (< 50 min old)? ──► Return cached accessToken
       └── Missing / expired / 401? ───────────► Popup: GoogleAuthProvider + scope(drive.file)
                                                 Extract (credential as OAuthCredential).accessToken
                                                 Cache token + expiry (50 min) in memory
       │
       ▼
[FirestoreSchoolRepository.saveAttachmentToDrive()]
  POST /api/saveAttachmentToDrive
  { studentId, msgId, attachmentName, downloadPath, accessToken, folderId, folderName, savedBy }
       │
       ▼
[Cloud Function: exports.saveAttachmentToDrive (functions/index.js -> functions/src/drive_service.js)]
       │
       ├── 1. Authenticate LibrusClient & call resolveAttachmentDownloadUrl(downloadPath)
       │      -> https://sandbox.librus.pl/GetFile/{token}/get
       │
       ├── 2. Download binary Buffer via axios.get(directUrl, { responseType: "arraybuffer" })
       │      Infer MIME type from filename (.pdf, .pptx, .docx, .xlsx, .jpg, .png, .zip, etc.)
       │
       ├── 3. Upload to Google Drive REST API v3:
       │      POST https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,mimeType,webViewLink,parents
       │      Headers: Authorization: Bearer <accessToken>, Content-Type: multipart/related; boundary=...
       │      Metadata part: { name: attachmentName, parents: folderId && folderId !== 'root' ? [folderId] : undefined }
       │      Media part: binary Buffer
       │      (If folderId returns 404 Not Found -> automatic fallback to 'root' "Mój dysk")
       │
       └── 4. Persist DriveAttachmentInfo in Firestore:
              students/{studentId}.messages[msgId].driveAttachments[attachmentName] = {
                driveFileId, webViewLink, folderId: effectiveFolderId,
                folderName: effectiveFolderName, savedAt: ISO8601, savedBy
              }
       │
       ▼
[Client receives DriveAttachmentInfo]
       ├── Tile icon switches from Spinner -> "Otwórz w Google Drive" (Icons.cloud_done_rounded / Icons.open_in_new_rounded)
       └── Shows Gmail-style SnackBar:
           "Zapisano w: {folderName}" + Action: ["Zmień folder / Przenieś"]
                  │
                  ▼ (If clicked)
           [DriveFolderPickerModal]
             ├── Lists folders via GET /api/driveFolder (q: mimeType='application/vnd.google-apps.folder' and trashed=false)
             ├── Allows creating new folder via POST /api/driveFolder (action: 'create')
             └── Moves file(s) via POST /api/driveFolder (action: 'move', fileIds, addParents, removeParents)
                 Updates students/{studentId}.messages[msgId].driveAttachments[attachmentName]
                 Optionally saves default folder preference (driveDefaultFolderId, driveDefaultFolderName)
```

### Recommended Project Structure

```
functions/
├── index.js                         # Exports saveAttachmentToDrive & manageDriveFolders endpoints
├── src/
│   ├── drive_service.js             # Multipart builder, MIME resolver, Drive REST v3 upload/list/create/move, Firestore updater
│   ├── librus_client.js             # Existing resolveAttachmentDownloadUrl(downloadPath) + downloadAttachmentBuffer(downloadPath)
│   └── sync_service.js              # Updated mergeAndIndexMessages() to preserve driveAttachments & attachmentFiles
└── test/
    └── drive_service.test.js        # Unit tests for multipart body construction, MIME detection, folder move & sync preservation

lib/
├── core/
│   └── auth/
│       └── firebase_auth_service.dart # Extended with requestGoogleDriveAccessToken() + in-memory token cache
├── domain/
│   └── models/
│       └── message_thread.dart      # DriveAttachmentInfo model + driveAttachments map on MessageItem, MessageThread, MessageDetailsResult
├── data/
│   └── repositories/
│       ├── school_repository.dart   # Interface methods: saveAttachmentToDrive, listDriveFolders, createDriveFolder, moveDriveAttachments, default folder getters/setters
│       ├── firestore_school_repository.dart # Implementation calling /api/saveAttachmentToDrive & /api/driveFolder + Firestore/SharedPreferences default folder
│       └── mock_school_repository.dart      # Demo mode simulation for saving/moving attachments on Drive
└── presentation/
    ├── screens/
    │   ├── main_navigation_screen.dart      # Profile/Settings sheet item for configuring default Google Drive folder (D-03)
    │   └── messages/
    │       ├── message_thread_screen.dart   # Attachment tile dual actions (Download + Drive) & "Zapisz wszystkie na Dysku" (or delegated to MessageAccordionTile if Phase 21 ran first)
    │       └── widgets/
    │           └── drive_folder_picker_modal.dart # Modal for "Zmień folder / Przenieś" & Settings default folder configuration
```

> **Note on Phase 21 / Phase 22 Compatibility:** Phase 21 decomposes `message_thread_screen.dart` into `lib/presentation/screens/messages/widgets/message_accordion_tile.dart`. Currently `lib/presentation/screens/messages/widgets/` does not exist yet (`message_thread_screen.dart` has 1,502 lines `[VERIFIED: lib/presentation/screens/messages/message_thread_screen.dart:1066-1200]`). Extracting the attachment section into a dedicated widget (e.g., `MessageAttachmentsSection` or inside `MessageAccordionTile`) ensures clean separation whether Phase 22 executes before or after Phase 21.

---

### Pattern 1: Obtaining & Caching Google OAuth `accessToken` with Scope `drive.file`

**What:** `FirebaseAuthService` (`lib/core/auth/firebase_auth_service.dart:36-69`) currently signs in with `email` and `profile` scopes. Under **D-09**, we only request `https://www.googleapis.com/auth/drive.file` (non-invasive scope granting access strictly to files and folders created by EduSync). To avoid opening a popup on every attachment click during a session (especially when saving multiple attachments), cache `_cachedDriveAccessToken` and `_driveTokenExpiry` in static memory for 50 minutes (Google OAuth access tokens are valid for 3600 seconds / 60 minutes).

**When to use:** Whenever `saveAttachmentToDrive`, `saveAllAttachmentsToDrive`, or `DriveFolderPickerModal` needs a valid Google Drive OAuth token.

```dart
// Source: [VERIFIED: lib/core/auth/firebase_auth_service.dart:36-69] + Firebase Auth Web OAuthCredential API
static const String googleDriveFileScope = 'https://www.googleapis.com/auth/drive.file';
static String? _cachedDriveAccessToken;
static DateTime? _driveTokenExpiry;

bool get hasValidDriveAccessToken {
  if (_cachedDriveAccessToken == null || _cachedDriveAccessToken!.isEmpty) return false;
  if (_driveTokenExpiry == null) return false;
  return DateTime.now().isBefore(_driveTokenExpiry!);
}

void clearDriveAccessToken() {
  _cachedDriveAccessToken = null;
  _driveTokenExpiry = null;
}

Future<String?> requestGoogleDriveAccessToken({bool forceRefresh = false}) async {
  if (!forceRefresh && hasValidDriveAccessToken) {
    return _cachedDriveAccessToken;
  }

  final auth = _auth;
  if (auth == null) {
    throw Exception('Firebase Auth nie jest zainicjalizowany.');
  }

  final provider = GoogleAuthProvider();
  provider.addScope('email');
  provider.addScope('profile');
  provider.addScope(googleDriveFileScope);
  if (forceRefresh) {
    provider.setCustomParameters({'prompt': 'consent'});
  }

  UserCredential userCredential;
  final current = auth.currentUser;
  if (kIsWeb) {
    if (current != null && !current.isAnonymous) {
      try {
        userCredential = await current.reauthenticateWithPopup(provider);
      } catch (_) {
        userCredential = await auth.signInWithPopup(provider);
      }
    } else {
      userCredential = await auth.signInWithPopup(provider);
    }
  } else {
    userCredential = await auth.signInWithProvider(provider);
  }

  final oauthCred = userCredential.credential as OAuthCredential?;
  final token = oauthCred?.accessToken;
  if (token != null && token.isNotEmpty) {
    _cachedDriveAccessToken = token;
    _driveTokenExpiry = DateTime.now().add(const Duration(minutes: 50));
  }
  return token;
}
```

> **Tip:** Also capture the `accessToken` if the user signs in with Google during initial login (or if `signInWithGoogle` includes `googleDriveFileScope` or when `requestGoogleDriveAccessToken` is first triggered). Keeping `requestGoogleDriveAccessToken` on-demand on first Drive interaction guarantees existing logged-in sessions work seamlessly via `reauthenticateWithPopup` / `signInWithPopup`.

---

### Pattern 2: Server-Side Binary Fetch from Librus & `multipart/related` Upload to Google Drive REST API v3

**What:** In `functions/src/librus_client.js:775-795` `[VERIFIED: functions/src/librus_client.js:775-795]`, `resolveAttachmentDownloadUrl(downloadPath)` resolves `/wiadomosci/pobierz_zalacznik/{msgId}/{attId}` to `https://sandbox.librus.pl/GetFile/{token}/get`.
We add `downloadAttachmentBuffer(downloadPath)` on `LibrusClient` (or in `drive_service.js`) which calls `resolveAttachmentDownloadUrl(downloadPath)` and then fetches the binary payload using `this.client.get(directUrl, { responseType: "arraybuffer", timeout: 45000 })`.
Then `drive_service.js` constructs a standard RFC 2387 `multipart/related` body containing:
1. Part 1 (`application/json; charset=UTF-8`): `{ name: attachmentName, parents: folderId && folderId !== 'root' ? [folderId] : undefined }`
2. Part 2 (`<detectedMimeType>`): raw `Buffer` of the file
And posts it to `https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,mimeType,webViewLink,parents`.

**Why `Buffer.concat` instead of string concatenation:** Binary files (PDF, PPTX, DOCX, ZIP, images) will be corrupted if converted to UTF-8 strings during multipart assembly. Always construct the preamble and epilogue as UTF-8 `Buffer`s and join them with the binary file `Buffer` via `Buffer.concat([preambleBuf, fileBuffer, epilogueBuf])`.

```javascript
// Source: Google Drive REST API v3 Multipart Upload specification [CITED: developers.google.com/drive/api/guides/manage-uploads#multipart]
function buildMultipartRelatedBody({ metadata, fileBuffer, mimeType, boundary = "edusync_drive_boundary_22" }) {
  const metadataJson = JSON.stringify(metadata);
  const preamble =
    `--${boundary}\r\n` +
    `Content-Type: application/json; charset=UTF-8\r\n\r\n` +
    `${metadataJson}\r\n` +
    `--${boundary}\r\n` +
    `Content-Type: ${mimeType || "application/octet-stream"}\r\n\r\n`;
  const epilogue = `\r\n--${boundary}--`;

  return {
    contentType: `multipart/related; boundary=${boundary}`,
    bodyBuffer: Buffer.concat([
      Buffer.from(preamble, "utf8"),
      Buffer.isBuffer(fileBuffer) ? fileBuffer : Buffer.from(fileBuffer),
      Buffer.from(epilogue, "utf8"),
    ]),
  };
}
```

---

### Pattern 3: Gmail-Style Immediate Save + „Zmień folder / Przenieś” Flow (D-01, D-02, D-03)

**What:**
1. **Default Folder Resolution:**
   - Stored in Firestore `students/{studentId}` under `driveDefaultFolderId` (default `'root'`) and `driveDefaultFolderName` (default `'Mój dysk'`), mirrored locally in `SharedPreferences` (`edusync_drive_default_folder_id`, `edusync_drive_default_folder_name`).
2. **Immediate Upload on Click:**
   - User clicks `Icons.add_to_drive_rounded` on a single attachment (or „Zapisz wszystkie na Dysku” in the attachments header when `message.attachments.length >= 2`).
   - Without showing any blocking modal before upload, the client immediately uploads to the active default folder (`driveDefaultFolderId` or `'root'`).
   - If the configured `driveDefaultFolderId` was deleted by the user on Google Drive (Drive API returns `404`), the backend automatically retries upload to `'root'` (`Mój dysk`) so the save never fails unexpectedly.
3. **Confirmation SnackBar with „Zmień folder / Przenieś”:**
   - As soon as upload completes, display a floating `SnackBar`:
     - Single file: `Zapisano „matura2027.pdf” w: Mój dysk`
     - Bulk save: `Zapisano 2 załączniki w: Mój dysk`
     - Action button: `Zmień folder / Przenieś`
4. **Moving & Setting Default Folder in `DriveFolderPickerModal`:**
   - Clicking `Zmień folder / Przenieś` opens `DriveFolderPickerModal` passing the newly created `driveFileId`(s) and current `folderId`.
   - The modal lists existing folders accessible under `drive.file` scope:
     `GET https://www.googleapis.com/drive/v3/files?q=mimeType='application/vnd.google-apps.folder' and trashed=false&fields=files(id,name,webViewLink)&orderBy=name`
   - Includes a permanent top option: **„Mój dysk (katalog główny)”** (`id: 'root'`).
   - Includes a **„+ Nowy folder”** inline input (e.g. default suggestion `EduSync - Załączniki szkolne` or `Szkoła`) which calls:
     `POST https://www.googleapis.com/drive/v3/files?fields=id,name,webViewLink` with `{ name: folderName, mimeType: 'application/vnd.google-apps.folder' }`.
   - Includes a checkbox **„Ustaw jako domyślny folder dla przyszłych załączników”** (checked by default).
   - Confirming calls `/api/driveFolder` (`action: 'move'`) which invokes:
     `PATCH https://www.googleapis.com/drive/v3/files/{fileId}?addParents={targetFolderId}&removeParents={previousFolderId}&fields=id,name,webViewLink,parents`
     and updates `driveAttachments` + `driveDefaultFolderId`/`driveDefaultFolderName` in Firestore `students/{studentId}`!

---

### Pattern 4: Preserving `driveAttachments` Across Background Syncs in `sync_service.js`

**What:** `functions/src/sync_service.js` runs every 15 minutes (`scheduledLibrusSync`) and on manual sync (`syncNow`). In `mergeAndIndexMessages` (`functions/src/sync_service.js:341-422`), `freshMessages` are scraped freshly from Librus HTML.
If we do not copy `prev.driveAttachments` (and `prev.attachmentFiles` / `prev.attachments` when not re-scraped) from `prevMessages` onto `merged`, any background sync will overwrite `students/{login}.messages` and erase `driveAttachments`!

```javascript
// Source: [VERIFIED: functions/src/sync_service.js:364-389]
for (const m of merged) {
  const prev = prevById.get(String(m.id));
  if (prev) {
    // Always preserve Google Drive saved attachments metadata across syncs (Phase 22, D-07)
    if (prev.driveAttachments && typeof prev.driveAttachments === "object") {
      m.driveAttachments = {
        ...prev.driveAttachments,
        ...(m.driveAttachments || {}),
      };
    }
    // Preserve previously fetched attachmentFiles if fresh scrape only fetched inbox table headers
    if (
      (!Array.isArray(m.attachmentFiles) || m.attachmentFiles.length === 0) &&
      Array.isArray(prev.attachmentFiles) &&
      prev.attachmentFiles.length > 0
    ) {
      m.attachmentFiles = prev.attachmentFiles;
      m.attachments = prev.attachments || prev.attachmentFiles.map(a => a.name);
      m.hasAttachments = true;
    }
  }
  if (m.bodyLoaded === true) continue;
  // ... existing body preservation logic
}
```

Also in `exports.getMessageDetails` (`functions/index.js:463-483`), when updating `m` in `students/{login}.messages`, we leave `m.driveAttachments` intact on the message object and return `driveAttachments: m.driveAttachments || {}` in the JSON response so the client always gets the latest Drive state.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Google Drive OAuth flow | Custom OAuth2 redirect endpoints, client secrets in frontend, or `google_sign_in` plugin | `FirebaseAuthService` with `GoogleAuthProvider().addScope('https://www.googleapis.com/auth/drive.file')` and `OAuthCredential.accessToken` | Already integrated with Firebase Auth Web; handles popup lifecycle and token issuance securely without storing client secrets. |
| Browser-side Librus attachment download | Client-side `http.get('https://sandbox.librus.pl/GetFile/...')` in Flutter Web | Server-side Cloud Function `/api/saveAttachmentToDrive` using `LibrusClient.resolveAttachmentDownloadUrl` + `axios` (`arraybuffer`) | `sandbox.librus.pl` does not send `Access-Control-Allow-Origin` headers; browser XHR/fetch will fail with a CORS error, whereas server-to-server `axios` succeeds and avoids double-transferring megabytes through the client's mobile/web connection (**D-10**). |
| Heavy Google APIs SDK in Cloud Functions | Installing `googleapis` (180+ MB) in `functions/package.json` | Direct Google Drive REST API v3 calls via `axios` in `functions/src/drive_service.js` | Only 4 REST endpoints are needed; `axios` keeps Cloud Function cold starts fast and avoids dependency bloat. |
| Full-access Google Drive scope | Requesting `https://www.googleapis.com/auth/drive` (restricted scope) | `https://www.googleapis.com/auth/drive.file` (non-sensitive scope) | `drive` full scope triggers Google's restricted scope security verification warning screen; `drive.file` is non-sensitive, recommended by Google, and sufficient for creating folders and uploading/moving school attachments (**D-09**). |

**Key insight:** Under `drive.file` scope, the application has full permission to create folders, list folders it created, upload files into those folders (or `'root'`), and move those files between `'root'` and any folder created by the app.

---

## Common Pitfalls

### Pitfall 1: Corrupting Binary Attachments in `multipart/related` Upload
**What goes wrong:** Uploaded PDFs or PPTX files appear on Google Drive with the right filename, but fail to open ("Nie można wyświetlić pliku") because binary bytes were coerced to a UTF-8 string when concatenating multipart boundaries.
**Why it happens:** Using template literals `` `--${boundary}\r\n...${fileBuffer}\r\n--${boundary}--` `` converts `fileBuffer` to a UTF-8 string, replacing non-UTF8 byte sequences with `U+FFFD` (`ef bf bd`).
**How to avoid:** Always keep the downloaded attachment as a `Buffer` (`responseType: 'arraybuffer'` -> `Buffer.from(res.data)`) and use `Buffer.concat([Buffer.from(preamble, 'utf8'), fileBuffer, Buffer.from(epilogue, 'utf8')])`.
**Warning signs:** File size on Drive is ~30-50% larger than original binary size, or PDF header `%PDF-1.` contains `ef bf bd` bytes.

### Pitfall 2: Losing `driveAttachments` During Scheduled 15-Minute Librus Sync
**What goes wrong:** User saves an attachment to Google Drive, sees „Otwórz w Google Drive”, and 15 minutes later after `scheduledLibrusSync` runs, the icon reverts back to „Zapisz na Dysku”.
**Why it happens:** `syncStudentData` replaces `messages` in `students/{studentId}` with the output of `mergeAndIndexMessages`, which previously only copied `body`, `preview`, and `bodyLoaded`.
**How to avoid:** Explicitly merge `prev.driveAttachments` (and `prev.attachmentFiles`) in `mergeAndIndexMessages` in `functions/src/sync_service.js` for all messages (including top-10 messages where `m.bodyLoaded === true`).
**Warning signs:** `driveAttachments` disappears from Firestore after calling `/api/syncNow`.

### Pitfall 3: Popup Blocked by Browser if `signInWithPopup` Runs After an Async Network Call
**What goes wrong:** Browser blocks the Google OAuth popup window if an `await http.get(...)` call happens *before* `requestGoogleDriveAccessToken()` is called on user tap.
**Why it happens:** Modern browsers (Chrome, Safari, Firefox) require `window.open` (used internally by `signInWithPopup` / `reauthenticateWithPopup`) to be triggered directly from a user gesture before long network roundtrips expire the transient user activation.
**How to avoid:** In the click handler (`_saveAttachmentToDrive` / `_saveAllAttachmentsToDrive` / `_openDriveFolderPicker`), call `await ref.read(firebaseAuthServiceProvider).requestGoogleDriveAccessToken()` **first**, before making any `/api/messageDetails` or `/api/saveAttachmentToDrive` HTTP calls!
**Warning signs:** `firebase_auth/popup-blocked` exception in browser console.

### Pitfall 4: Expired OAuth Access Token (HTTP 401 from Google Drive API)
**What goes wrong:** User keeps the EduSync tab open for > 1 hour and clicks „Zapisz na Dysku”; the cached `accessToken` has expired and Drive API returns `401 Unauthorized`.
**Why it happens:** Google OAuth 2.0 access tokens expire after 3600 seconds.
**How to avoid:**
1. Set local cache TTL to 50 minutes (`Duration(minutes: 50)`).
2. If `/api/saveAttachmentToDrive` or `/api/driveFolder` returns HTTP `401` (`UNAUTHENTICATED`), call `authService.clearDriveAccessToken()` and surface a clear prompt/retry that invokes `requestGoogleDriveAccessToken(forceRefresh: true)`.

### Pitfall 5: Deleted Target Folder on Google Drive (HTTP 404 from Drive API)
**What goes wrong:** User configured a default folder „Szkoła”, later deleted that folder in Google Drive web UI, and then clicked „Zapisz na Dysku” in EduSync.
**Why it happens:** `parents: [folderId]` references a non-existent Drive file ID, causing Drive API to return `404 File not found`.
**How to avoid:** In `drive_service.js`, if uploading with `parents: [folderId]` returns `404`, automatically retry the upload without `parents` (which saves to `'root'` / „Mój dysk”) and return `folderId: 'root', folderName: 'Mój dysk', fallbackToRoot: true`.

---

## Code Examples

### 1. Domain Model: `DriveAttachmentInfo` in `lib/domain/models/message_thread.dart`

```dart
// Source: [VERIFIED: lib/domain/models/message_thread.dart:1-126]
class DriveAttachmentInfo {
  final String driveFileId;
  final String webViewLink;
  final String folderId;
  final String folderName;
  final DateTime savedAt;
  final String savedBy;

  const DriveAttachmentInfo({
    required this.driveFileId,
    required this.webViewLink,
    this.folderId = 'root',
    this.folderName = 'Mój dysk',
    required this.savedAt,
    this.savedBy = 'Rodzic',
  });

  factory DriveAttachmentInfo.fromMap(Map<String, dynamic> map) {
    return DriveAttachmentInfo(
      driveFileId: (map['driveFileId'] ?? '').toString(),
      webViewLink: (map['webViewLink'] ?? '').toString(),
      folderId: (map['folderId'] ?? 'root').toString(),
      folderName: (map['folderName'] ?? 'Mój dysk').toString(),
      savedAt: DateTime.tryParse((map['savedAt'] ?? '').toString()) ?? DateTime.now(),
      savedBy: (map['savedBy'] ?? 'Rodzic').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'driveFileId': driveFileId,
        'webViewLink': webViewLink,
        'folderId': folderId,
        'folderName': folderName,
        'savedAt': savedAt.toIso8601String(),
        'savedBy': savedBy,
      };
}
```

### 2. Cloud Function Service: `functions/src/drive_service.js`

```javascript
// Source: Google Drive REST API v3 [CITED: developers.google.com/drive/api/reference/rest/v3/files]
const axios = require("axios");

const MIME_BY_EXT = {
  ".pdf": "application/pdf",
  ".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  ".ppt": "application/vnd.ms-powerpoint",
  ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  ".doc": "application/msword",
  ".odt": "application/vnd.oasis.opendocument.text",
  ".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  ".xls": "application/vnd.ms-excel",
  ".csv": "text/csv",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".zip": "application/zip",
  ".rar": "application/vnd.rar",
  ".7z": "application/x-7z-compressed",
  ".txt": "text/plain",
};

function guessMimeType(fileName = "") {
  const lower = String(fileName).toLowerCase().trim();
  const dotIdx = lower.lastIndexOf(".");
  if (dotIdx !== -1) {
    const ext = lower.slice(dotIdx);
    if (MIME_BY_EXT[ext]) return MIME_BY_EXT[ext];
  }
  return "application/octet-stream";
}

async function uploadBufferToDrive({
  accessToken,
  fileName,
  fileBuffer,
  mimeType,
  folderId = "root",
  folderName = "Mój dysk",
  httpClient = axios,
}) {
  const effectiveMime = mimeType || guessMimeType(fileName);
  const hasCustomFolder = folderId && folderId !== "root" && folderId.trim() !== "";
  const metadata = {
    name: fileName,
    ...(hasCustomFolder ? { parents: [folderId.trim()] } : {}),
  };

  const { contentType, bodyBuffer } = buildMultipartRelatedBody({
    metadata,
    fileBuffer,
    mimeType: effectiveMime,
  });

  const uploadUrl =
    "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,mimeType,webViewLink,parents";

  try {
    const res = await httpClient.post(uploadUrl, bodyBuffer, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": contentType,
        "Content-Length": bodyBuffer.length,
      },
      maxBodyLength: Infinity,
      maxContentLength: Infinity,
      timeout: 45000,
    });
    const data = res.data || {};
    return {
      driveFileId: data.id,
      webViewLink: data.webViewLink || `https://drive.google.com/file/d/${data.id}/view`,
      folderId: hasCustomFolder ? folderId.trim() : "root",
      folderName: hasCustomFolder ? folderName || "Folder Google Drive" : "Mój dysk",
      fallbackToRoot: false,
    };
  } catch (err) {
    // Fallback to 'root' if custom folder was deleted on Drive (404)
    if (hasCustomFolder && err.response?.status === 404) {
      return uploadBufferToDrive({
        accessToken,
        fileName,
        fileBuffer,
        mimeType: effectiveMime,
        folderId: "root",
        folderName: "Mój dysk",
        httpClient,
      });
    }
    throw err;
  }
}

async function moveDriveFileToFolder({
  accessToken,
  fileId,
  targetFolderId,
  previousFolderId = "root",
  httpClient = axios,
}) {
  const addParents = targetFolderId && targetFolderId !== "root" ? targetFolderId : "root";
  const removeParents = previousFolderId && previousFolderId !== "root" ? previousFolderId : "root";
  const url =
    `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}` +
    `?addParents=${encodeURIComponent(addParents)}` +
    `&removeParents=${encodeURIComponent(removeParents)}` +
    `&fields=id,name,webViewLink,parents`;

  const res = await httpClient.patch(
    url,
    {},
    {
      headers: { Authorization: `Bearer ${accessToken}` },
      timeout: 20000,
    }
  );
  return res.data;
}
```

### 3. `firebase.json` Rewrites for Phase 22 Endpoints

```json
// Source: [VERIFIED: firebase.json:63-70]
{
  "source": "/api/saveAttachmentToDrive",
  "function": {
    "functionId": "saveAttachmentToDrive",
    "region": "europe-west3"
  }
},
{
  "source": "/api/driveFolder",
  "function": {
    "functionId": "manageDriveFolders",
    "region": "europe-west3"
  }
}
```

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Firebase Auth Google OAuth 2.0 popup (`GoogleAuthProvider`) with short-lived bearer `accessToken`. |
| V3 Session Management | yes | OAuth `accessToken` is kept strictly in browser memory (`_cachedDriveAccessToken`) and never written to Firestore or `localStorage`. |
| V4 Access Control | yes | Least-privilege OAuth scope `https://www.googleapis.com/auth/drive.file` (**D-09**) — app cannot read or modify any personal Drive files outside those created by EduSync. |
| V5 Input Validation | yes | Validate `downloadPath` prefix `/wiadomosci/pobierz_zalacznik/` (`[VERIFIED: functions/src/librus_client.js:777]`) to prevent SSRF; validate `msgId`, `attachmentName`, and `folderId`. |
| V6 Cryptography | no | All OAuth and TLS cryptography handled by Firebase Auth & Google APIs over HTTPS. |

### Known Threat Patterns for Cloud Functions + Google Drive REST API

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SSRF via `downloadPath` parameter | Tampering / Elevation of Privilege | Enforce strict regex `/^\/wiadomosci\/pobierz_zalacznik\/\d+\/\d+$/` in `LibrusClient.resolveAttachmentDownloadUrl` before making any request to Librus `[VERIFIED: functions/src/librus_client.js:735,777]`. |
| OAuth `accessToken` leakage in logs or DB | Information Disclosure | Never log `accessToken` in `console.log` or `librus_query_logs`, and never persist `accessToken` in Firestore `students/{studentId}` (persist only `driveFileId`, `webViewLink`, `folderId`, `folderName`, `savedAt`, `savedBy`). |
| Drive query injection in folder creation/listing | Tampering | Escape single quotes in folder names (`name.replace(/\\/g, "\\\\").replace(/'/g, "\\'")`) when querying Drive API `q` parameter, or create folders via JSON body `POST /drive/v3/files`. |

---

## Assumptions Log

All claims in this research were verified against the repository source files or cited from official Google Drive REST API v3 / Firebase Auth documentation. No `[ASSUMED]` items remain.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Client app & widget tests | ✓ | `3.38.5` (Dart `3.10.4`) `[VERIFIED: flutter --version]` | — |
| Node.js | Cloud Functions & unit tests | ✓ | `v25.5.0` `[VERIFIED: node --version]` | — |
| npm | Cloud Functions package runner | ✓ | `11.8.0` `[VERIFIED: npm --version]` | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework (Backend) | Node.js built-in test runner (`node --test`) `[VERIFIED: functions/package.json:5]` |
| Framework (Frontend) | `flutter_test` (`flutter test`) `[VERIFIED: pubspec.yaml:52-53]` |
| Config file | `functions/package.json` & `pubspec.yaml` |
| Quick run command | `node --test functions/test/drive_service.test.js && flutter test test/message_attachments_test.dart` |
| Full suite command | `npm --prefix functions test && flutter analyze && flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-DRIVE-01 | `drive_service.js` builds valid `multipart/related` binary buffers, resolves MIME types, uploads to Drive, lists/creates folders, moves files via `addParents`/`removeParents`, and falls back to `root` on 404 | unit | `node --test functions/test/drive_service.test.js` | ❌ Wave 1 |
| REQ-DRIVE-02 | `mergeAndIndexMessages` in `sync_service.js` preserves `driveAttachments` and `attachmentFiles` across background Librus sync cycles | unit | `node --test functions/test/message_body_indexing.test.js` | ✅ (`functions/test/message_body_indexing.test.js`) |
| REQ-DRIVE-01, REQ-DRIVE-02 | `MessageThreadScreen` renders dual actions (`Icons.download_rounded` + `Icons.add_to_drive_rounded`), bulk „Zapisz wszystkie na Dysku” for >=2 attachments, switches saved attachments to „Otwórz w Google Drive”, and shows SnackBar with „Zmień folder / Przenieś” | widget | `flutter test test/message_attachments_test.dart` | ✅ (`test/message_attachments_test.dart` — to be expanded) |

### Sampling Rate
- **Per task commit:** `node --test functions/test/drive_service.test.js && flutter analyze`
- **Per wave merge:** `npm --prefix functions test && flutter test test/message_attachments_test.dart`
- **Phase gate:** `npm --prefix functions test && flutter analyze && flutter test && flutter build web --release`

### Wave 0 Gaps
- [ ] `functions/test/drive_service.test.js` — unit tests for `buildMultipartRelatedBody`, `guessMimeType`, `uploadBufferToDrive` (including 404 folder fallback to `root`), `moveDriveFileToFolder`, and Firestore `driveAttachments` persistence (created in Wave 1).
- [ ] Expand `test/message_attachments_test.dart` — widget tests covering single attachment Drive save, bulk „Zapisz wszystkie na Dysku”, „Otwórz w Google Drive” state, and „Zmień folder / Przenieś” modal flow.

---

## Sources

### Primary (HIGH confidence)
- `[VERIFIED: functions/src/librus_client.js:729-795]` — `_parseMessageAttachments($)` and `resolveAttachmentDownloadUrl(downloadPath)` resolving `/wiadomosci/pobierz_zalacznik/{msgId}/{attId}` to `https://sandbox.librus.pl/GetFile/{token}/get`.
- `[VERIFIED: functions/index.js:430-548]` — `exports.getMessageDetails` and `exports.downloadAttachment` endpoints and Firestore `students/{login}.messages` update pattern.
- `[VERIFIED: functions/src/sync_service.js:341-422]` — `mergeAndIndexMessages` message preservation across sync cycles.
- `[VERIFIED: lib/core/auth/firebase_auth_service.dart:36-69]` — `GoogleAuthProvider` and `signInWithPopup` setup on Flutter Web.
- `[VERIFIED: lib/domain/models/message_thread.dart:1-126]` — `MessageDetailsResult`, `MessageItem`, and `MessageThread` models.
- `[VERIFIED: lib/presentation/screens/messages/message_thread_screen.dart:1066-1200]` — Current attachment chips rendering and `_downloadAttachment` method.
- `[VERIFIED: lib/presentation/screens/main_navigation_screen.dart:384-556]` — Profile & Settings bottom sheet (`_showProfileSheet`) where user-level and family-level settings are accessed.

### Secondary (MEDIUM confidence)
- `[CITED: developers.google.com/drive/api/guides/manage-uploads#multipart]` — Google Drive API v3 `multipart/related` upload specification (`POST https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart`).
- `[CITED: developers.google.com/drive/api/guides/folder]` — Creating folders (`application/vnd.google-apps.folder`) and moving files between folders (`PATCH /drive/v3/files/{fileId}?addParents=...&removeParents=...`).

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Zero external dependencies required; all libraries (`firebase_auth`, `axios`, `cloud_firestore`, `http`, `shared_preferences`) are already verified in the repository.
- Architecture: HIGH — Directly extends existing `/api/downloadAttachment` and `students/{studentId}.messages` patterns established in Quick Task `260928-ogq` and Phase 20.
- Pitfalls: HIGH — Identified binary `Buffer.concat` requirement, `mergeAndIndexMessages` sync preservation gap, popup user-gesture ordering, and deleted-folder fallback.

**Research date:** 2026-09-28
**Valid until:** 2026-10-28
