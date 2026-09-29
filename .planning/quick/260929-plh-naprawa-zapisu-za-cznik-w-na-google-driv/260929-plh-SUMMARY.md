# 260929-plh — SUMMARY

**Status:** ✅ Zakończone

## Przyczyna
Google Drive API było **wyłączone** w projekcie Google Cloud `lepsza-szkola`. Drive odpowiadał 403,
a backend tłumaczył każde 401/403 jako „Sesja Google Drive wygasła”, więc ponowna autoryzacja nic nie dawała.

## Zmiany
- Włączono `drive.googleapis.com` w projekcie `lepsza-szkola` (stan: ENABLED).
- `functions/src/drive_service.js`: nowa funkcja `classifyDriveError()`.
- `functions/index.js`: handlery zapisu i folderów używają klasyfikatora + logują `error.response.data` z Google.
- Frontend bez zmian — 401/403 przychodzą teraz tylko przy realnym problemie z tokenem/zgodą; inne błędy pokazują faktyczny powód.

## Testy
- `node --test functions/test/drive_service.test.js` — 9/9 (3 nowe dla klasyfikatora).
