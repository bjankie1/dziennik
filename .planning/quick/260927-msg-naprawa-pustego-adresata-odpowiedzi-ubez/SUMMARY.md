# Quick Task 260927-msg Summary: Naprawa pustego adresata odpowiedzi na wiadomość "Ubezpieczenie szkolne"

## Przyczyna błędu
1. Wiadomość **"ubezpieczenie szkolne"** (`id: 1248339`) została wysłana w Librusie z konta **`[Administrator szkoły]`** (podpisana w treści przez: *Kamila Buczek - szkolna Rada Rodziców*, z kopią wysłaną do dyr. *Bentkowska-Sztonyk Zofia*).
2. W `FirestoreSchoolRepository.getMessages()` wyrażenie `senderRaw.replaceAll(RegExp(r'\[.*?\]'), '').trim()` wycinało wszystko w nawiasach kwadratowych `[...]`, przez co dla nadawcy `"[Administrator szkoły]"` zwracało **pusty ciąg znaków `""`**.
3. Dodatkowo w `functions/src/librus_client.js` wyrażenie `sender.replace(/\s*\([^)]*\)/, "")` wycinało nazwisko w nawiasie okrągłym nawet wtedy, gdy przed nawiasem nie było żadnego tekstu.

## Co zostało naprawione
1. **Poprawne rozpoznawanie nadawców `[Administrator szkoły]` oraz podpisów z treści (`firestore_school_repository.dart`, `librus_client.js`)**:
   - Jeśli po usunięciu `[...]` nazwa nadawcy byłaby pusta, zachowywana jest rola z nawiasu (`Administrator szkoły`) wzbogacona o podpis z treści wiadomości: **`Kamila Buczek - szkolna Rada Rodziców (Administrator szkoły)`**.
2. **Wizualna lista adresatów i obsługa DW w formularzu odpowiedzi (`message_thread_screen.dart`)**:
   - W sekcji `Odpowiedź do:` wyświetlany jest wyraźny chip adresata.
   - Jeśli wiadomość zawiera stopkę Librusa `Kopia powyższej wiadomości została wysłana do nauczyciela: ...` (w tym przypadku `Bentkowska-Sztonyk Zofia`), pojawia się szybki przycisk **`+ DW: Bentkowska-Sztonyk Zofia`** oraz menu **`+ Dodaj adresata`** z listą nauczycieli.
