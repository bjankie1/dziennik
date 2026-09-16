# Phase 7: Funkcjonalny moduł wiadomości (czytanie, odpowiadanie, wysyłanie) - Context

**Gathered:** 2026-09-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Dostarczenie pełnej, dwukierunkowej obsługi wiadomości Librus Synergia w aplikacji:
1. Widok wątku wiadomości na jednym ekranie w stylu Gmail (chronologiczna historia, zwijane/rozwijane wiadomości).
2. Szybka odpowiedź bezpośrednio z poziomu widoku wątku z wysyłaniem do Librus Synergia.
3. Formularz tworzenia nowej wiadomości z autocomplete odbiorcy po nazwisku nauczyciela oraz po nauczanym przedmiocie (np. "Chemia", "Pietrzak") z obsługą wielu odbiorców w postaci chipów.
4. Integracja backendowa Cloud Functions ze scraperem Librusa dla pobierania pełnej treści wiadomości i wysyłania odpowiedzi / nowych wiadomości.

</domain>

<decisions>
## Implementation Decisions

### Układ widoku wątku w stylu Gmail
- **D-01:** Dedykowany pełny ekran wątku (`ThreadScreen`) z płynną nawigacją z listy głównej i czytelnym AppBarze z przyciskiem powrotu oraz tematem wątku.
- **D-02:** Chronologiczny układ wiadomości (najstarsza na górze, najnowsza na dole). Wcześniejsze wiadomości zwinięte do kompaktowych 1-liniowych pasków (nadawca, data, fragment), klikalne w celu rozwinięcia/zwinięcia. Najnowsza wiadomość domyślnie w pełni rozwinięta.
- **D-03:** Przycisk „Odpowiedz” umieszczony na dole pod ostatnią wiadomością, który po dotknięciu rozwija zintegrowane pole tekstowe z przyciskiem „Wyślij” (dokładnie jak w Gmailu).
- **D-04:** Górny AppBar zawiera przycisk powrotu, temat wątku oraz ikony akcji: odśwież i oznacz jako przeczytaną/nieprzeczytaną.

### Formularz tworzenia nowej wiadomości i Autocomplete
- **D-05:** Dedykowany ekran / arkusz tworzenia wiadomości (`NewMessageScreen`) zawierający pole „Do:”, „Temat”, „Treść” oraz wyraźny przycisk „Wyślij”.
- **D-06:** Baza odbiorców do autocomplete czerpana ze znanych powiązań Nauczyciel ↔ Przedmiot (z profilu ucznia, planu lekcji i ocen) z opcjonalnym doładowaniem pełnej listy odbiorców z Librusa.
- **D-07:** Pole wyszukiwania reaguje na wpisywanie zarówno nazwiska nauczyciela (np. „Pietrzak”), jak i nazwy przedmiotu (np. „chemia”). Wyniki prezentowane w rozwijanej liście z awatarem, nazwiskiem i etykietą przedmiotu/roli.
- **D-08:** Po wybraniu nauczyciel staje się usuwalnym „chipem” (pigułką z krzyżykiem `x`) w polu „Do:”.
- **D-09:** Obsługa wielu odbiorców bez ograniczeń — możliwość dodania wielu pigułek nauczycieli w polu „Do:” jednej wiadomości.

### Pobieranie i prezentacja pełnej treści wiadomości
- **D-10:** Tabela skrzynki odbiorczej Librusa udostępnia jedynie nagłówki. Pełna treść wiadomości (`div.container-message-content`) musi być pobierana z podstron szczegółów wiadomości (zarówno automatycznie dla ostatnich wiadomości, jak i on-demand przez endpoint `/api/messageDetails`), trwale zapisywana w profilu ucznia w Firestore oraz prezentowana w `MessageThreadScreen` ze wskaźnikiem ładowania i możliwością odświeżenia.

### the agent's Discretion
- Dokładny layout i animacja rozwijania/zwijania wiadomości w wątku.
- Obsługa trybu offline / demo (optymistyczne dodawanie wiadomości do stanu lokalnego).
- Formatowanie dat i godzin w wiadomościach.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Roadmap
- `.planning/ROADMAP.md` — Wymagania i kryteria sukcesu Fazy 7.
- `.planning/REQUIREMENTS.md` — Wymagania REQ-MSG-04, REQ-MSG-05, REQ-MSG-06.

### Existing Message Models & UI
- `lib/domain/models/message_thread.dart` — Istniejące modele `MessageThread` i `Announcement`.
- `lib/presentation/screens/messages/messages_screen.dart` — Aktualny ekran listy wiadomości i ogłoszeń.
- `lib/data/repositories/firestore_school_repository.dart` — Repozytorium z obsługą wiadomości i powiadomień.
- `functions/src/librus_client.js` — Istniejący scraper Librusa (`fetchMessages`).

</canonical_refs>
