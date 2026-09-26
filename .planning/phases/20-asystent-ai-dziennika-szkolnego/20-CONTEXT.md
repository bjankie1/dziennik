# Phase 20: Asystent AI dziennika szkolnego (Konwersacyjny agent Q&A) - Context

**Gathered:** 2026-09-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Wdrożenie konwersacyjnego Asystenta AI dziennika szkolnego zintegrowanego z pływającym widżetem Czatu (z przełącznikiem rozmówcy: „Oskar / Rodzic” ↔ „Asystent AI ✨”, bez dodawania nowej zakładki w menu głównym), odpowiadającego po polsku na pytania o oceny, plan lekcji, sprawdziany, wiadomości (wraz z pełną treścią `body` o wycieczkach i zebraniach), ogłoszenia, nieobecności i zadania To-Do, z klikalnymi odnośnikami do źródeł oraz szybkimi akcjami (`+ Kalendarz Google`, `+ Dodaj zadanie`).

</domain>

<decisions>
## Implementation Decisions

### Umiejscowienie w UI i pływający widżet Czatu (Floating Chat Button)
- **D-01:** Czat działa jako **pływający przycisk (Floating Chat Button / Panel)** dostępny w aplikacji, który po otwarciu pozwala wybrać adresata wiadomości za pomocą przełącznika (Segmented Control / Tabs w nagłówku okienka czatu): **„Oskar / Rodzic (Czat rodzinny)”** albo **„Asystent AI ✨”**.
- **D-02:** **Nie dodajemy żadnej nowej, osobnej zakładki** w głównym menu bocznym (`AppSidebar`) ani dolnym pasku nawigacji dla Asystenta AI — Asystent jest częścią modułu czatu (zarówno w pływającym okienku czatu, jak i na istniejącym ekranie `/czat`).

### Silnik AI (Firebase AI Logic + Gemini 3) i zakres kanałów
- **D-03:** Silnik konwersacyjny oparty o **Firebase AI Logic (`firebase_ai` SDK w trybie `FirebaseAI.googleAI(auth: FirebaseAuth.instance)`)** korzystający z darmowego **Gemini Developer API Free Tier** na projekcie Firebase `lepsza-szkola` (uruchamiany przez `npx firebase-tools init ailogic`, bez konieczności ręcznego zarządzania kluczami API).
- **D-03b:** Domyślnym modelem językowym jest najnowszy stabilny **Gemini 3.8 Flash (`gemini-3.8-flash` / `gemini-flash-latest`)**, a w nagłówku czatu AI dostępny jest przełącznik pozwalający przełączyć się na **Gemini 3.1 Pro (`gemini-3.1-pro-preview`)** dla bardziej złożonych pytań analitycznych.
- **D-04:** Asystent AI działa **wyłącznie w czacie w aplikacji webowej/mobilnej**. Kanał Telegram pozostaje przeznaczony wyłącznie do jednostronnych powiadomień (Faza 18) oraz Piątkowego Briefingu (Faza 19).

### Indeksowanie pełnej treści wiadomości Librus (`body`)
- **D-05:** Aby Agent AI potrafił odpowiadać na pytania o wydarzenia ukryte wewnątrz wiadomości o ogólnych tytułach (np. *„Kiedy jest wycieczka Oskara do Warszawy?”*, *„Kiedy jest zebranie z rodzicami?”*), proces synchronizacji w tle (`sync_service.js`) **automatycznie dogrywa pełne treści (`body`) niepobranych wiadomości** po kilka sztuk (np. 3–5 wiadomości) na cykl synchronizacji z zachowaniem losowego jittera i zasad ciszy nocnej z Fazy 11, aż zbuforuje pełną treść ostatnich ~30–40 wiadomości w Firestore (`students/{studentId}/messages_full` oraz polu `body` na liście `messages`).

### Interaktywne źródła, szybkie akcje i prywatność wątku AI
- **D-06:** Dymki odpowiedzi Asystenta AI zawierają:
  1. Konkretną odpowiedź w języku polskim opartą wyłącznie na danych z dziennika (zakaz halucynowania dat lub faktów spoza kontekstu),
  2. Klikalne pigułki cytowanych źródeł (np. `📩 Otwórz wiadomość: Wycieczka...`, `📅 Pokaż w planie: 02.10`, `🎓 Oceny`), które przekierowują przez `go_router` bezpośrednio do odpowiedniego widoku,
  3. Kontekstowe przyciski szybkiej akcji (`+ Kalendarz Google` oraz `+ Dodaj zadanie`), gdy odpowiedź dotyczy terminu sprawdzianu, wycieczki, zebrania lub składki.
- **D-07:** Historia rozmowy z Asystentem AI jest **osobna dla każdego użytkownika** (`parent` ma własny wątek z AI, a `student` / Oskar ma swój własny wątek z AI w `students/{studentId}/ai_chats/{role}_messages`) z przyciskiem **„Wyczyść czat”** oraz zestawem gotowych chipów startowych (*„Kiedy jest następny sprawdzian?”*, *„Kiedy jest wycieczka Oskara do Warszawy?”*, *„Kiedy jest zebranie z rodzicami?”*, *„Jakie są nieusprawiedliwione nieobecności?”*).

### the agent's Discretion
- Format strukturyzacji promptu systemowego (System Prompt) dla Gemini 3.8 Flash / Gemini 3.1 Pro oraz JSON Schema (`responseMimeType: 'application/json'`) dla zwracanych źródeł (`sources[]`) i wykrytych wydarzeń kalendarzowych (`suggestedEvent` / `suggestedTask`).
- Automatyczny fallback z `gemini-3.8-flash` do `gemini-flash-latest` w przypadku przejściowej niedostępności konkretnego endpointu modelu.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project & Phase Specs
- `.planning/ROADMAP.md` — Definicja celu i kryteriów sukcesu dla Phase 20
- `.planning/REQUIREMENTS.md` — Wymagania `REQ-AI-01` oraz `REQ-AI-02`

### Existing Chat, Navigation & Data Layer
- `lib/presentation/screens/main_navigation_screen.dart` — Główny kontener nawigacji (miejsce osadzenia globalnego pływającego przycisku Czatu)
- `lib/presentation/screens/chat/family_chat_screen.dart` — Istniejący widok Czatu Rodzinnego (do rozszerzenia o przełącznik „Oskar / Rodzic” ↔ „Asystent AI ✨”)
- `lib/presentation/providers/family_chat_provider.dart` — Provider czatu rodzinnego i modeli wiadomości
- `lib/core/utils/calendar_export_service.dart` — Istniejący serwis generowania linków `+ Kalendarz Google` oraz plików `.ics` (do reużycia w akcjach pod odpowiedziami AI)
- `lib/presentation/widgets/common/linked_task_action_bar.dart` — Wspólny wzorzec tworzenia zadań To-Do (z Fazy 17.1)
- `functions/src/sync_service.js` — Cykl synchronizacji Librus (miejsce stopniowego dogrywania pełnych treści wiadomości `body` z poszanowaniem jittera Fazy 11)
- `functions/src/librus_scraper.js` — Metoda `fetchMessageContent` pobierająca pełną treść wiadomości z Librus Synergia

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FamilyChatScreen` (`lib/presentation/screens/chat/family_chat_screen.dart`): Posiada już gotowy układ dymków wiadomości, pasek wpisywania tekstu i obsługę przewijania — można go bezpośrednio wykorzystać w pływającym panelu czatu i wyposażyć w przełącznik trybu (`Czat z Oskarem/Rodzicem` vs `Asystent AI ✨`).
- `CalendarExportService.openGoogleCalendarForExam` (`lib/core/utils/calendar_export_service.dart`): Gotowy generator URL do Kalendarza Google, który można wywołać jednym kliknięciem z dymku odpowiedzi AI dla wykrytej wycieczki, zebrania lub sprawdzianu.
- `TasksRepository` / `TaskFormModal`: Gotowe tworzenie zadań z predefiniowanym tytułem, terminem i `sourceId`.
- `LibrusScraper.fetchMessageContent` (`functions/src/librus_scraper.js`): Gotowa metoda scrapująca pełną treść pojedynczej wiadomości Librus i zapisująca ją w `students/{studentId}/messages_full/{messageId}`.

### Established Patterns
- Dyskretne odpytywanie Librusa (Phase 11): każde dodatkowe zapytanie HTTP do Librusa w `sync_service.js` musi używać losowego jittera (`1.2s–2.5s`) i limitu (np. maks. 3–4 niepobrane wiadomości na 1 cykl synchronizacji), aby nie obciążać sesji.

### Integration Points
- `MainNavigationScreen`: Dodanie pływającego przycisku czatu (Floating Action Button z badge'em nieprzeczytanych wiadomości od Oskara + ikoną ✨ AI), otwierającego okienko/panel czatu na dowolnym ekranie.
- `functions/index.js`: Nowy endpoint Cloud Function `askSchoolAssistant` (oraz opcjonalny fallback bezpośredni w kliencie przez REST API Gemini) budujący pełny kontekst z dokumentu `students/{studentId}`, subkolekcji `messages_full` i `tasks`.

</code_context>

<specifics>
## Specific Ideas

- Przykładowe pytania startowe wyświetlane jako klikalne pigułki w Asystencie AI:
  - *„Kiedy jest następny sprawdzian?”*
  - *„Kiedy jest wycieczka Oskara do Warszawy?”*
  - *„Kiedy jest zebranie z rodzicami?”*
  - *„Jakie są nieusprawiedliwione nieobecności?”*
- Pływający przycisk czatu pozwala w jednym okienku przełączać się między rozmową z Oskarem/Rodzicem a rozmową z Agentem AI bez tworzenia nowej pozycji w nawigacji.

</specifics>

<deferred>
## Deferred Ideas

- Zadawanie pytań do Asystenta AI przez bota Telegram (dwukierunkowy webhook Telegram) — świadomie wyłączone z zakresu (Telegram służy wyłącznie do jednostronnych powiadomień i piątkowego raportu).

</deferred>

---

*Phase: 20-asystent-ai-dziennika-szkolnego*
*Context gathered: 2026-09-26*
