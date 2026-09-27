---
phase: quick-260927-msg
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/data/repositories/firestore_school_repository.dart
  - lib/presentation/screens/messages/message_thread_screen.dart
  - functions/src/librus_client.js
autonomous: true
---

# Quick Task 260927-msg: Naprawa pustego adresata odpowiedzi na wiadomość "Ubezpieczenie szkolne"

## Cel
Usunięcie błędu powodującego pustą nazwę nadawcy/adresata (`Odpowiedź do: `) w wiadomościach wysłanych z konta `[Administrator szkoły]` (np. "ubezpieczenie szkolne") oraz dodanie wizualnych pigułek adresatów, podpowiedzi nauczyciela z kopii (DW) i wyboru adresata z listy nauczycieli.

## Zadania
1. **Naprawa parsera nadawcy w `FirestoreSchoolRepository` i `LibrusClient`**:
   - W `FirestoreSchoolRepository`: nie dopuścić do wyczyszczenia `cleanName` do pustego stringa po usunięciu `[...]` (dla `[Administrator szkoły]`); wyciągać podpis z treści wiadomości (`Kamila Buczek - szkolna Rada Rodziców (Administrator szkoły)`) oraz rozpoznawać rolę `Administrator szkoły`.
   - W `LibrusClient.fetchMessages`: nie usuwać nawiasów okrągłych `(Imię Nazwisko)`, jeśli przed nawiasem nie ma tekstu (odpakować nawias zamiast go wycinać).
2. **Ulepszenie sekcji odpowiedzi w `MessageThreadScreen`**:
   - Wyświetlanie adresatów jako wyraźnych chipów obok `Odpowiedź do:`.
   - Automatyczne wykrywanie adnotacji Librusa `Kopia powyższej wiadomości została wysłana do nauczyciela: ...` (np. `Bentkowska-Sztonyk Zofia`) jako przycisku szybkiego dodania `+ DW: ...`.
   - Możliwość dodania dowolnego nauczyciela z listy (`+ Dodaj adresata`).
