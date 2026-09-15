# Phase 7: Funkcjonalny moduł wiadomości (czytanie, odpowiadanie, wysyłanie) - Research

**Researched:** 2026-09-15
**Confidence:** HIGH

## User Constraints
*Source: `07-CONTEXT.md`*

- **D-01:** Dedykowany pełny ekran wątku (`ThreadScreen`) z płynną nawigacją z listy głównej i czytelnym AppBarze z przyciskiem powrotu oraz tematem wątku.
- **D-02:** Chronologiczny układ wiadomości (najstarsza na górze, najnowsza na dole). Wcześniejsze wiadomości zwinięte do kompaktowych 1-liniowych pasków (nadawca, data, fragment), klikalne w celu rozwinięcia/zwinięcia. Najnowsza wiadomość domyślnie w pełni rozwinięta.
- **D-03:** Przycisk „Odpowiedz” umieszczony na dole pod ostatnią wiadomością, który po dotknięciu rozwija zintegrowane pole tekstowe z przyciskiem „Wyślij” (dokładnie jak w Gmailu).
- **D-04:** Górny AppBar zawiera przycisk powrotu, temat wątku oraz ikony akcji: odśwież i oznacz jako przeczytaną/nieprzeczytaną.
- **D-05:** Dedykowany ekran / arkusz tworzenia wiadomości (`NewMessageScreen`) zawierający pole „Do:”, „Temat”, „Treść” oraz wyraźny przycisk „Wyślij”.
- **D-06:** Baza odbiorców do autocomplete czerpana ze znanych powiązań Nauczyciel ↔ Przedmiot (z profilu ucznia, planu lekcji i ocen) z opcjonalnym doładowaniem pełnej listy odbiorców z Librusa.
- **D-07:** Pole wyszukiwania reaguje na wpisywanie zarówno nazwiska nauczyciela (np. „Pietrzak”), jak i nazwy przedmiotu (np. „chemia”). Wyniki prezentowane w rozwijanej liście z awatarem, nazwiskiem i etykietą przedmiotu/roli.
- **D-08:** Po wybraniu nauczyciel staje się usuwalnym „chipem” (pigułką z krzyżykiem `x`) w polu „Do:”.
- **D-09:** Obsługa wielu odbiorców bez ograniczeń — możliwość dodania wielu pigułek nauczycieli w polu „Do:” jednej wiadomości.

## Standard Stack & Existing Components

### Frontend (Flutter / Riverpod)
- **State Management:** `flutter_riverpod` (`messagesProvider`, `messageThreadProvider(id)`, `teachersProvider`).
- **UI Components:**
  - `InputChip` / `Chip` dla wybranych odbiorców w polu `Do:`.
  - `RawAutocomplete` / `Autocomplete` z niestandardowym `optionsViewBuilder` dla inteligentnego filtrowania (imię, nazwisko, przedmiot, rola).
  - `AnimatedCrossFade` / `ExpansionTile` / niestandardowy accordion dla zwijanych wiadomości w wątku Gmail.
- **Theme & Colors:** `AppColors` z Material 3 (`surfaceContainerLowest`, `primary`, `outline`, itp.).

### Backend (Cloud Functions & Librus Scraper)
- **Scraping / Sessions:** `LibrusClient` w `functions/src/librus_client.js` z obsługą sesji na cookie jar `tough-cookie` / `axios-cookiejar-support`.
- **Endpoints:**
  - `GET /api/messageDetails?id=...&login=...` – pobranie szczegółów wiadomości (lub pełnego wątku).
  - `POST /api/sendMessage` – wysłanie nowej wiadomości lub odpowiedzi (parametry: `login`, `recipients[]`, `subject`, `body`, `replyToId`).

## Architecture Patterns

### 1. Model wątku i wiadomości cząstkowych
```dart
class MessageItem {
  final String id;
  final String senderName;
  final String senderRole;
  final String senderInitials;
  final DateTime timestamp;
  final String body;
  final bool isFromMe;
  final List<String> attachments;
}

class MessageThread {
  final String id;
  final String subject;
  final List<MessageItem> messages;
  final bool isUnread;
  final bool isImportant;
}
```

### 2. Autocomplete Nauczycieli (Imię, Nazwisko, Przedmiot)
```dart
class TeacherContact {
  final String id;
  final String name;
  final String subject;
  final String role;
  
  bool matches(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) || 
           subject.toLowerCase().contains(q) || 
           role.toLowerCase().contains(q);
  }
}
```

### 3. Ekran Wątku w stylu Gmail (`MessageThreadScreen`)
- Nagłówek: Temat wątku, status przeczytania, przycisk odświeżenia.
- Lista wiadomości:
  - Dla indeksu `i < messages.length - 1`: kompaktowy kafelek (avatar, imię, data, 1 linijka tekstu), po kliknięciu rozwija pełną treść.
  - Dla ostatniej wiadomości (`i == messages.length - 1`): domyślnie rozwinięta cała treść wiadomości.
- Dół ekranu:
  - Przycisk `Odpowiedz` z ikoną `Icons.reply`.
  - Po kliknięciu: płynnie pojawia się formularz odpowiedzi (wieloliniowy `TextField` + przyciski `Anuluj` i `Wyślij`).

## Don't Hand-Roll
- Nie twórz skomplikowanego własnego parsera tagów HTML w wiadomościach Librusa — użyj czyszczenia tekstu ze znaczników (`RegExp(r'<[^>]*>')`) lub wyświetlania tekstu z zachowaniem akapitów `\n\n`.
- Nie blokuj UI podczas wysyłania odpowiedzi — zastosuj optymistyczny update (dodanie nowej wiadomości do wątku z oznaczeniem wysyłania/sukcesu).

## Common Pitfalls & Edge Cases
1. **Puste lub bardzo długie wątki:** Zwijanie starszych wiadomości zapobiega przepełnieniu ekranu przy wielokrotnej wymianie korespondencji.
2. **Brak internetu / błąd sesji Librusa:** Jeśli Cloud Function zwróci błąd sesji lub Librus odrzuci formularz, wyświetlić czytelny SnackBar z opcją ponów i nie kasować wpisanego tekstu w polu odpowiedzi.
3. **Wielu odbiorców:** Wyszukiwarka po wybraniu nauczyciela czyści pole tekstowe i dopisuje chip do listy wybranych, pozwalając na wpisanie kolejnego.
