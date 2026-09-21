# Phase 4 Context: Bezpieczny autologin i trwałe powiązanie profilu Librus

**Phase:** 04-bezpieczny-autologin-i-trwale-powiazanie-profilu-librus  
**Author:** Pair programming session  
**Date:** 2026-09-15  

## User Directives & Locked Decisions

### 1. Trwałość sesji przy przeładowaniu strony (F5 / Cmd+R / reload)
- **Problem użytkownika:** "Chciałbym aby przeładowanie strony nie powodowało wylogowania."
- **Przyczyna źródłowa:**
  1. `appUserProvider` w Riverpod był stanem wyłącznie w pamięci RAM (`return null` przy każdym reboocie Fluttera).
  2. `FirebaseAuth.instance.authStateChanges` na Web potrzebuje ułamka sekundy na odczyt z IndexedDB; w tym czasie stan był traktowany jako wylogowany, wyrzucając do `LoginScreen`.
  3. `_keyExplicitDisconnect` w SharedPreferences blokował sprawdzenie połączenia w chmurze przy kolejnych wejściach.
- **Decyzja:**
  - `AppUser` oraz stan sesji użytkownika są trwale zapisywane w `SharedPreferences` (localStorage przeglądarki).
  - Przy starcie aplikacji stan zalogowania użytkownika i połączenia Librus jest natychmiast odzyskiwany z pamięci trwałej.
  - Przeładowanie strony (odświeżenie w przeglądarce) zachowuje stan i natychmiast wyświetla Pulpit bez żadnego wylogowania ani migotania ekranu logowania.

### 2. Autologin z Firestore
- Po zalogowaniu kontem Google aplikacja odpytuje endpoint `/api/getConnection?userId=${user.uid}`.
- Jeśli konto Librus zostało raz powiązane, poświadczenie/sparowanie jest trwale zapamiętane w chmurze (Firestore).
- Użytkownik nie musi ponownie wpisywać loginu i hasła Librusa.

### 3. Logika wylogowania
- **Wyloguj się z aplikacji:** czyści lokalną pamięć sesji i wylogowuje z Google, ale **nie niszczy** powiązania Librus w Firestore. Ponowne zalogowanie tym samym kontem Google automatycznie wczytuje dane.
- **Rozłącz konto Librus:** świadoma, dedykowana akcja, która trwale odłącza Librusa w Firestore i lokalnie.

## Boundaries & Constraints
- Żadnych wrażliwych haseł w repozytorium gita.
- Zgodność z Flutter Web oraz mobile.
