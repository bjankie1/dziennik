---
id: 260919-ufy
slug: naprawa-rozpoznawania-usprawiedliwie-i-z
title: Naprawa rozpoznawania usprawiedliwień i zwolnień w module frekwencji
created: 2026-09-19
status: in-progress
---

# Quick Task: Naprawa rozpoznawania usprawiedliwień i zwolnień w module frekwencji

## Diagnoza problemu
1. **Librus Synergia używa skrótów i formatowania HTML**:
   - W tooltipie Librus umieszcza: `Rodzaj: nieobecność uspr.<br>Data: 2026-09-01 (wt.) ...`
   - Kod w `functions/src/librus_client.js` sprawdzał `kind.includes("usprawiedliw") || symbol === "u"`.
   - Dla daty 2026-09-01 `kind` to `"nieobecność uspr."` (nie zawiera `"usprawiedliw"`), a `symbol` to `"unb"` (nie równa się `"u"`). Z tego powodu usprawiedliwiona lekcja trafiła do `unexcused`!
2. **Brak obsługi zwolnień (`zwolnienie` / `zw`)**:
   - Lekcje z 16, 17 i 18 września to `Rodzaj: zwolnienie` (symbol `zw`). Wpadły do gałęzi `else` jako `unexcused` (nieobecność nieusprawiedliwiona do usprawiedliwienia przez rodzica).
3. **Brak uzgadniania (reconciliation) frekwencji z modułem e-Usprawiedliwień**:
   - `fetchJustifications()` pobiera z Librusa tabelę zaakceptowanych wniosków:
     - `2026-09-01, lekcja: 2` -> `usprawiedliwione (Sobota Łukasz)`
     - `2026-09-02, lekcja: 2` -> `usprawiedliwione (Sobota Łukasz)`
   - Te dane nie były łączone z listą rekordów frekwencji, przez co stan zaakceptowania nie propagował się do widoku frekwencji.
4. **Klient Flutter**:
   - `FirestoreSchoolRepository` nie posiadał logiki defensywnej dla `data['justifications']` ani dla `zwolnienie` / `uspr.`.

## Planowane zadania

### Task 1: Backend — Poprawa klasyfikacji frekwencji i uzgadnianie z e-Usprawiedliwieniami
- **Pliki:**
  - `functions/src/librus_client.js`
  - `functions/test/attendance_parsing.test.js` (nowy test jednostkowy)
- **Zakres:**
  - Rozszerzenie reguł rozpoznawania w `fetchAttendance`:
    - Usprawiedliwione: `kind.includes("uspr")`, `kind.includes("usprawiedliw")`, `tooltip.includes("e-Usprawiedliwienia")`, `symbol` zawierający `u` (np. `unb`, `u`, `uspr`).
    - Zwolnienia: `kind.includes("zwoln")`, `symbol.startsWith("zw")` -> klasyfikacja jako `exempted` (zwolnienie) lub `excused` (nie obciąża licznika nieusprawiedliwionych).
    - Spóźnienia: `kind.includes("spóźn")`, `symbol.startsWith("sp")`.
  - W `fetchAllStudentData()`: uzgadnianie rekordów frekwencji z pobraną listą `justifications` (jeśli wniosek ma status `usprawiedliwione` / `zaakceptowane`, rekord otrzymuje `type: 'excused'` oraz `justificationStatus: 'approved'`).
  - Dodanie testów jednostkowych w `functions/test/`.

### Task 2: Frontend — Obsługa `exempted` i defensywne uzgadnianie w repozytorium
- **Pliki:**
  - `lib/data/repositories/firestore_school_repository.dart`
  - `lib/presentation/screens/attendance/attendance_screen.dart`
- **Zakres:**
  - W `FirestoreSchoolRepository.getAttendanceRecords()`: mapowanie `exempted` / `zwolnienie` na `AttendanceType.exempted`.
  - Powiązanie rekordów z listą `data['justifications']` po dacie i numerze lekcji.
  - W `AttendanceScreen`: czytelna prezentacja zwolnień (np. status "Zwolnienie z zajęć" z szarym/niebieskim znacznikiem informacyjnym, bez wymogu usprawiedliwiania).

### Task 3: Weryfikacja i publikacja
- Uruchomienie testów backendu (`npm test`) i analizera Flutter (`flutter analyze`).
- Wdrożenie zaktualizowanych Cloud Functions (`firebase deploy --only functions`).
- Wdrożenie zaktualizowanego frontendu na Hosting (`flutter build web` + `firebase deploy --only hosting`).
- Weryfikacja stanu przez wywołanie API i sprawdzenie rekordów ucznia.
