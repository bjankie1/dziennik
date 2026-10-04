# Phase 25: Archiwizacja wiadomości, automatyczna archiwizacja potwierdzeń usprawiedliwień i powiadomienia o akceptacji - Context

**Gathered:** 2026-10-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Uporządkowanie modułu Wiadomości oraz domknięcie pętli informacyjnej o usprawiedliwieniach nieobecności:
1. **Ręczna archiwizacja i przywracanie wiadomości** (z poziomu listy w `MessagesScreen` oraz widoku wątku w `MessageThreadScreen`), wraz z filtrem (chipem) **„Pokaż zarchiwizowane”** wewnątrz zakładki `Wiadomości`.
2. **Automatyczna archiwizacja i oznaczanie jako przeczytane** systemowych wiadomości potwierdzających akceptację usprawiedliwienia przez wychowawcę (np. od nadawcy `Usprawiedliwienia` / `System Librus` lub o temacie dotyczącym zaakceptowanego usprawiedliwienia), tak aby nie zaśmiecały głównej skrzynki odbiorczej ani nie zawyżały licznika nieprzeczytanych wiadomości.
3. **Czytelna prezentacja zaakceptowanych usprawiedliwień w module Frekwencji (`AttendanceScreen`)** — dodanie licznika na filtrze `Usprawiedliwione (X)`, karty podsumowania zaakceptowanych wniosków e-Usprawiedliwień na górze listy oraz wyraźnego statusu „Zaakceptowano przez wychowawcę” wraz z powodem przy każdej usprawiedliwionej godzinie lekcyjnej.
4. **Powiadomienia o akceptacji usprawiedliwienia** (typ `justification`) wysyłane przy wykryciu zaakceptowania usprawiedliwienia (zarówno z nowej wiadomości systemowej, jak i ze zmiany statusu wniosku / nieobecności na usprawiedliwioną) do wszystkich sparowanych czatów Telegram (Rodzic i Uczeń), Web Push oraz do zakładki „Ostatnie alerty”.

</domain>

<decisions>
## Implementation Decisions

### 1. Przeglądanie i obsługa zarchiwizowanych wiadomości (`MessagesScreen` & `MessageThreadScreen`)
- **D-01 (Filtr chip „Pokaż zarchiwizowane” wewnątrz zakładki Wiadomości):** W zakładce `Wiadomości` (`_activeTab == 0` w `MessagesScreen`) dodajemy przełączalny chip filtrujący **„Pokaż zarchiwizowane (X)”** (lub przełącznik widoku Aktywne / Zarchiwizowane w pasku akcji nad listą wiadomości). Domyślnie lista pokazuje wyłącznie wiadomości aktywne (`!thread.isArchived`), a po aktywowaniu chipa pokazuje wiadomości zarchiwizowane (lub pozwala łatwo przywrócić je do skrzynki odbiorczej).
- **D-02 (Akcje ręcznej archiwizacji i przywracania):**
  - Na karcie wiadomości w `MessagesScreen` (`_buildMessageCard` / `_buildMessageTaskActionRow`) oraz w pasku `AppBar` widoku wątku (`MessageThreadScreen`) dostępny jest przycisk **„Archiwizuj”** (`Icons.archive_outlined`) lub **„Przywróć”** (`Icons.unarchive_outlined`, gdy wiadomość jest już w archiwum) z komunikatem `SnackBar` i akcją `Cofnij`.
  - Stan zarchiwizowania (`isArchived: bool`) jest zapisywany lokalnie w `SharedPreferences` (`SchoolDataCacheManager`) oraz synchronizowany w Firestore (`students/{studentId}` w mapie `archivedMessageOverrides`), aby zachować spójność między urządzeniami.

### 2. Automatyczna archiwizacja potwierdzeń usprawiedliwień
- **D-03 (Reguła auto-archiwizacji i auto-odczytu):** Wiadomości systemowe dotyczące akceptacji usprawiedliwienia — rozpoznawane po nadawcy (`sender` zawierający `usprawiedliwieni` lub `system librus`) bądź temacie/treści (`zaakceptowano usprawiedliwienie`, `usprawiedliwienie zostało zaakceptowane`, `potwierdzenie usprawiedliwienia`) — są automatycznie oznaczane jako **zarchiwizowane (`isArchived: true`)** oraz **przeczytane (`isUnread: false`)** (o ile użytkownik ręcznie nie przywrócił danej wiadomości z archiwum).
- **D-04 (Czysta skrzynka i liczniki):** Automatycznie zarchiwizowane wiadomości nie pojawiają się w głównej liście nieprzeczytanych na Pulpicie (`DashboardScreen`) ani nie zwiększają licznika nieprzeczytanych wiadomości na zakładce `Wiadomości`. Nadal są w pełni dostępne po włączeniu filtra „Pokaż zarchiwizowane” oraz w indeksie Asystenta AI.

### 3. Podgląd zaakceptowanych usprawiedliwień w module Frekwencji (`AttendanceScreen`)
- **D-05 (Rozbudowa zakładki „Usprawiedliwione (X)”):**
  - Na pasku filtrów `AttendanceFilterBar` chip `Usprawiedliwione` wyświetla licznik usprawiedliwionych lekcji: **`Usprawiedliwione ($excusedCount)`**, spójnie z chipami `Do usprawiedliwienia ($unexcusedCount)` i `Oczekujące ($pendingCount)`.
  - Po wybraniu filtra `Usprawiedliwione` na górze listy wyświetlana jest karta podsumowania zaakceptowanych wniosków e-Usprawiedliwień (z datą/okresem, liczbą usprawiedliwionych godzin i powodem), a przy każdej usprawiedliwionej godzinie lekcyjnej widoczny jest wyraźny badge **„Zaakceptowano przez wychowawcę”** oraz powód usprawiedliwienia (jeśli jest dostępny).

### 4. Powiadomienia o akceptacji usprawiedliwienia (`sync_service.js` & `telegram_service.js`)
- **D-06 (Wykrywanie i wysyłka do Rodzica i Ucznia):**
  - Podczas synchronizacji w `functions/src/sync_service.js` wykrywamy akceptację usprawiedliwienia z dwóch źródeł (z deduplikacją, aby nie wysłać dwóch powiadomień o tym samym zdarzeniu):
    1. Nowa wiadomość systemowa o akceptacji usprawiedliwienia (zamiast zwykłego powiadomienia `type: "message"`, generuje powiadomienie `type: "justification"`, a sama wiadomość otrzymuje w snapshotcie flagę `isAutoArchived: true` i `isRead: true`).
    2. Zmiana statusu wpisu we frekwencji (`attendance`) z nieusprawiedliwionej/oczekującej na `excused` lub zmiana statusu wniosku w `justifications` na zaakceptowany.
  - Powiadomienie `type: "justification"` (`✅ Zaakceptowano usprawiedliwienie`) trafia do kolekcji `notifications` (widocznej w zakładce „Ostatnie alerty” oraz wyzwalającej Web Push) oraz jest wysyłane przez `telegram_service.js` do **wszystkich sparowanych czatów Telegram (zarówno Rodzica, jak i Ucznia)** z linkiem do `https://lepsza-szkola.web.app/frekwencja`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `lib/domain/models/message_thread.dart` — model `MessageThread` (dodanie pola `isArchived` oraz helpera rozpoznającego systemowe potwierdzenia usprawiedliwień).
- `lib/data/repositories/firestore/school_data_cache_manager.dart` — zarządzanie lokalnymi i zdalnymi nadpisaniami (`readOverrides`, dodanie `archiveOverrides`).
- `lib/data/repositories/firestore/firestore_messages_data_source.dart` — mapowanie wiadomości z Firestore, reguła auto-archiwizacji i auto-odczytu dla wiadomości systemowych o usprawiedliwieniach.
- `lib/presentation/screens/messages/messages_screen.dart` — chip „Pokaż zarchiwizowane”, filtrowanie listy, licznik nieprzeczytanych oraz przycisk archiwizacji/przywracania na karcie.
- `lib/presentation/screens/messages/message_thread_screen.dart` i `lib/presentation/screens/messages/widgets/message_thread_header_card.dart` — akcja archiwizacji/przywracania w widoku wątku oraz badge „Zarchiwizowana”.
- `lib/presentation/screens/attendance/attendance_screen.dart` i `lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart` — licznik `Usprawiedliwione (X)`, karta podsumowania zaakceptowanych usprawiedliwień oraz prezentacja statusu akceptacji.
- `functions/src/sync_service.js` i `functions/src/telegram_service.js` — wykrywanie zaakceptowanych usprawiedliwień, auto-archiwizacja wiadomości potwierdzających oraz formatowanie i wysyłka powiadomień `justification` na Telegram (Rodzic + Uczeń) i do „Ostatnich alertów”.

</canonical_refs>

<deferred>
## Deferred Ideas

Brak — wszystkie wymagania mieszczą się bezpośrednio w zakresie Fazy 25.

</deferred>

---
*Phase: 25-archiwizacja-wiadomo-ci-automatyczna-archiwizacja-potwierdze*
*Context gathered: 2026-10-04*
