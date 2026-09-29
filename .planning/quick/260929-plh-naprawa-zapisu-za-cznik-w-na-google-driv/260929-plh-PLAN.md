# 260929-plh — PLAN

**Problem:** Zapis załącznika „NNW dzieci LOX 26 1.pdf” na Google Drive kończył się komunikatem
`UNAUTHENTICATED_DRIVE: Sesja Google Drive wygasła.` – nawet po ponownym uzyskaniu tokenu.

**Diagnoza:**
- Service Usage API: `drive.googleapis.com` w projekcie `lepsza-szkola` miał stan **DISABLED**.
- Drive zwracał 403 (`accessNotConfigured` / `SERVICE_DISABLED`), a backend mapował **każde** 401/403
  (także z Librusa) na `UNAUTHENTICATED_DRIVE` → mylący komunikat „sesja wygasła”.

## Zadania
1. Włączyć Google Drive API w projekcie `lepsza-szkola` (Service Usage `:enable`).
2. `functions/src/drive_service.js`: `classifyDriveError()` —
   - 401 / `authError` / `insufficientPermissions` / `ACCESS_TOKEN_SCOPE_INSUFFICIENT` → 401 `UNAUTHENTICATED_DRIVE`,
   - `SERVICE_DISABLED` / `accessNotConfigured` → 503 `DRIVE_API_DISABLED`,
   - inne 403 Drive → 502 z oryginalnym komunikatem Google,
   - błędy spoza googleapis.com (np. Librus) → 502 `UPSTREAM_ERROR`.
3. `functions/index.js`: oba handlery (`saveAttachmentToDrive`, `manageDriveFolders`) używają klasyfikatora i logują pełną odpowiedź Google.
4. Testy w `functions/test/drive_service.test.js`; deploy funkcji `downloadAttachment`.
