---
phase: quick-260930-dhq
plan: 01
type: execute
autonomous: true
files_modified:
  - lib/domain/models/message_thread.dart
  - lib/data/repositories/firestore_school_repository.dart
  - lib/presentation/screens/messages/messages_screen.dart
  - lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart
  - lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart
  - functions/src/librus_client.js
  - test/presentation/screens/messages_timestamp_test.dart
must_haves:
  truths:
    - "Każda karta wiadomości na ekranie Wiadomości wyświetla rzeczywistą datę i godzinę wiadomości z pola thread.timestamp zamiast stałej etykiety z makiety"
    - "Formatowanie dat wiadomości poprawnie rozróżnia wiadomości z dzisiaj (Dzisiaj, HH:mm), z wczoraj (Wczoraj, HH:mm), starsze z bieżącego roku (d MMM, HH:mm) oraz z poprzednich lat (d MMM yyyy, HH:mm)"
    - "Parser dat wiadomości w FirestoreSchoolRepository odpornie parsuje daty z Librusa (YYYY-MM-DD HH:MM:SS, YYYY-MM-DD, DD.MM.YYYY HH:MM, wielokrotne białe znaki, Timestamp)"
  artifacts:
    - path: "lib/domain/models/message_thread.dart"
      provides: "MessageThread.formatTimestamp oraz getter formattedTimestamp"
    - path: "lib/presentation/screens/messages/messages_screen.dart"
      provides: "Dynamiczne wyświetlanie thread.formattedTimestamp na kartach wiadomości"
    - path: "test/presentation/screens/messages_timestamp_test.dart"
      provides: "Testy jednostkowe i widgetowe dat wiadomości"
  key_links:
    - from: "lib/presentation/screens/messages/messages_screen.dart"
      to: "lib/domain/models/message_thread.dart"
      via: "thread.formattedTimestamp in _buildMessageCard"
      pattern: "thread\\.formattedTimestamp"
---

<objective>
Naprawa wyświetlania dat i godzin wiadomości na liście w module „Wiadomości”, gdzie każda karta wiadomości pokazywała tę samą zahardkodowaną wartość z makiety HTML zamiast rzeczywistego czasu wiadomości (`thread.timestamp`).

Purpose: Wyeliminowanie zahardkodowanego czasu z prototypu w `MessagesScreen._buildMessageCard`, ujednolicenie formatowania dat wiadomości (Dzisiaj / Wczoraj / d MMM / d MMM yyyy) pomiędzy ekranem Wiadomości a Pulpitem oraz uodpornienie parsowania dat wiadomości w repozytorium i scraperze Librusa.
Output: Zaktualizowany model `MessageThread`, ekran `MessagesScreen`, widżety Pulpitu, parser w `FirestoreSchoolRepository` oraz testy w `test/presentation/screens/messages_timestamp_test.dart`.
</objective>

<execution_context>
@/Users/bjankiewicz/Projects/dziennik szkolny/.agents/gsd-core/workflows/execute-plan.md
@/Users/bjankiewicz/Projects/dziennik szkolny/.agents/gsd-core/templates/summary.md
</execution_context>

<context>
@/Users/bjankiewicz/Projects/dziennik szkolny/.planning/STATE.md
@/Users/bjankiewicz/Projects/dziennik szkolny/lib/domain/models/message_thread.dart
@/Users/bjankiewicz/Projects/dziennik szkolny/lib/presentation/screens/messages/messages_screen.dart
@/Users/bjankiewicz/Projects/dziennik szkolny/lib/data/repositories/firestore_school_repository.dart
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Dodanie formatera dat w MessageThread, odpornego parsera w repozytorium i zastąpienie stałej etykiety na kartach wiadomości</name>
  <files>
    lib/domain/models/message_thread.dart,
    lib/data/repositories/firestore_school_repository.dart,
    lib/presentation/screens/messages/messages_screen.dart,
    lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart,
    lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart,
    functions/src/librus_client.js
  </files>
  <read_first>
    lib/domain/models/message_thread.dart,
    lib/presentation/screens/messages/messages_screen.dart,
    lib/data/repositories/firestore_school_repository.dart,
    lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart,
    lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart,
    functions/src/librus_client.js
  </read_first>
  <behavior>
    - Test 1: `MessageThread.formatTimestamp` dla wiadomości z tego samego dnia co `now` (np. `2026-09-30 08:42`, `now = 2026-09-30 12:00`) zwraca `'Dzisiaj, 08:42'`.
    - Test 2: `MessageThread.formatTimestamp` dla wiadomości z poprzedniego dnia (np. `2026-09-29 14:05`, `now = 2026-09-30 12:00`) zwraca `'Wczoraj, 14:05'`.
    - Test 3: `MessageThread.formatTimestamp` dla starszej wiadomości z tego samego roku z godziną (np. `2026-09-18 11:20`) zwraca sformatowaną datę z godziną (`DateFormat('d MMM, HH:mm', 'pl_PL')`, np. `'18 wrz, 11:20'`), a dla daty bez godziny (`00:00:00`, np. `2026-09-18 00:00:00`) pomija sztuczną godzinę `'00:00'` i zwraca `'18 wrz'`.
    - Test 4: `MessageThread.formatTimestamp` dla wiadomości z innego roku (np. `2025-06-15 09:30`, `now = 2026-09-30 12:00`) zawiera rok (`DateFormat('d MMM yyyy, HH:mm', 'pl_PL')`).
    - Test 5: `FirestoreSchoolRepository.parseMessageDate` poprawnie parsuje `'2026-09-28 09:54:12'`, ciągi z podwójną spacją/nową linią `'2026-09-28\n09:54:12'`, samą datę `'2026-09-15'`, format `'28.09.2026 09:54'` oraz obiekt `{_seconds: ...}`.
  </behavior>
  <action>
    1. W `lib/domain/models/message_thread.dart`:
       - Zaimportuj `package:intl/intl.dart`.
       - W klasie `MessageThread` dodaj metodę statyczną `static String formatTimestamp(DateTime timestamp, {DateTime? now})` oraz getter `String get formattedTimestamp => formatTimestamp(timestamp);`.
       - W `formatTimestamp`: skonwertuj `final dt = timestamp.toLocal()` oraz `final refNow = (now ?? DateTime.now()).toLocal()`. Oblicz `today = DateTime(refNow.year, refNow.month, refNow.day)` i `msgDay = DateTime(dt.year, dt.month, dt.day)`, `dayDiff = today.difference(msgDay).inDays`. Sprawdź `final hasTime = dt.hour != 0 || dt.minute != 0 || dt.second != 0;`.
       - Jeśli `dayDiff == 0`: zwróć `hasTime ? 'Dzisiaj, ${DateFormat('HH:mm', 'pl_PL').format(dt)}' : 'Dzisiaj'`.
       - Jeśli `dayDiff == 1`: zwróć `hasTime ? 'Wczoraj, ${DateFormat('HH:mm', 'pl_PL').format(dt)}' : 'Wczoraj'`.
       - Jeśli `dt.year == refNow.year`: zwróć `hasTime ? DateFormat('d MMM, HH:mm', 'pl_PL').format(dt) : DateFormat('d MMM', 'pl_PL').format(dt)`.
       - W przeciwnym razie: zwróć `hasTime ? DateFormat('d MMM yyyy, HH:mm', 'pl_PL').format(dt) : DateFormat('d MMM yyyy', 'pl_PL').format(dt)`.
    2. W `lib/data/repositories/firestore_school_repository.dart`:
       - Dodaj statyczną metodę pomocniczą `static DateTime parseMessageDate(dynamic raw, {DateTime? fallback})`, która obsługuje:
         - `DateTime` -> `raw.toLocal()`
         - `num` -> `DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true).toLocal()`
         - `Map` zawierający `_seconds` lub `seconds` -> konwersja sekund na lokalny `DateTime`
         - obiekt z metodą `.toDate()` (Firestore `Timestamp`) -> `(raw as dynamic).toDate().toLocal()`
         - `String`: znormalizuj białe znaki przez `raw.trim().replaceAll(RegExp(r'\s+'), ' ')`. Najpierw spróbuj `DateTime.tryParse(cleaned)` (jeśli `isUtc`, wywołaj `.toLocal()`). Jeśli `tryParse` zwróci `null`, obsłuż format `DD.MM.YYYY` / `DD-MM-YYYY` z opcjonalnym `HH:MM(:SS)` za pomocą `RegExp(r'^(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$')`.
         - Gdy żadna reguła nie pasuje, zwróć `fallback ?? DateTime.now()`.
       - Użyj `parseMessageDate(item['date'])` w `getMessages()` (zamiast `DateTime.parse(item['date'] as String? ?? '')`) oraz `parseMessageDate(a['date'])` w `getAnnouncements()`.
    3. W `functions/src/librus_client.js` (w metodzie `fetchMessages` przy odczycie `tds[4]`):
       - Znormalizuj białe znaki w dacie wiadomości: `const date = $(tds[4]).text().trim().replace(/\s+/g, " ");`.
    4. W `lib/presentation/screens/messages/messages_screen.dart`:
       - W `_buildMessageCard(MessageThread thread)` (linia ~402-409) zastąp zahardkodowany ciąg z makiety wywołaniem `thread.formattedTimestamp`.
    5. W `lib/presentation/screens/dashboard/widgets/dashboard_messages_column.dart` (linia ~281) oraz `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` (linia ~897):
       - Zastąp lokalne `DateFormat('d MMM, HH:mm', 'pl_PL').format(msg.timestamp)` wywołaniem `msg.formattedTimestamp`, aby karty wiadomości na Pulpicie i w zakładce Wiadomości używały identycznego formatowania.
  </action>
  <verify>
    <automated>flutter analyze</automated>
  </verify>
  <done>
    `MessagesScreen`, `DashboardMessagesColumn` i `DashboardMobileView` wyświetlają `formattedTimestamp` wyliczony z rzeczywistego `timestamp` wiadomości, a `FirestoreSchoolRepository.parseMessageDate` bezpiecznie parsuje wszystkie formaty dat z Librusa.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Testy jednostkowe i widgetowe wyświetlania rzeczywistych dat wiadomości</name>
  <files>
    test/presentation/screens/messages_timestamp_test.dart
  </files>
  <read_first>
    lib/presentation/screens/messages/messages_screen.dart,
    lib/domain/models/message_thread.dart,
    lib/data/repositories/firestore_school_repository.dart,
    test/message_attachments_test.dart
  </read_first>
  <behavior>
    - Test 1: `MessageThread.formatTimestamp` zwraca poprawne polskie etykiety dla wiadomości z dzisiaj, wczoraj, wcześniejszych dni w tym samym roku (z godziną i bez godziny) oraz z poprzedniego roku.
    - Test 2: `FirestoreSchoolRepository.parseMessageDate` parsuje daty ISO/SQL z godziną, z wieloma spacjami/nową linią, same daty `YYYY-MM-DD`, polskie daty `DD.MM.YYYY HH:MM` oraz mapy `{_seconds}`.
    - Test 3: Widget test `MessagesScreen` z nadpisanym `messagesProvider` (zawierającym wiadomości od `Piwnik Ewa`, `Sobota Łukasz`, `e-Usprawiedliwienia`, `Radomyska Aneta` z różnymi datami) wyświetla dla każdej karty jej własną sformatowaną datę.
  </behavior>
  <action>
    Utwórz plik testowy `test/presentation/screens/messages_timestamp_test.dart`:
    1. Zainicjalizuj polskie dane lokalizacyjne `initializeDateFormatting('pl_PL', null)` i `initializeDateFormatting('pl', null)` w `setUpAll`.
    2. Dodaj grupę testów jednostkowych dla `MessageThread.formatTimestamp` sprawdzającą przypadki: dzisiaj z godziną, wczoraj z godziną, starszy dzień w tym samym roku z godziną, starszy dzień bez godziny (`00:00:00`), oraz dzień z poprzedniego roku.
    3. Dodaj grupę testów jednostkowych dla `FirestoreSchoolRepository.parseMessageDate` sprawdzającą ciągi `'2026-09-28 09:54:12'`, `'2026-09-28\n  09:54:12'`, `'2026-09-15'`, `'28.09.2026 14:30'` oraz `{'_seconds': 1790589252}`.
    4. Dodaj test widgetowy `MessagesScreen` renderujący listę 4 wątków (`Piwnik Ewa`, `Sobota Łukasz`, `e-Usprawiedliwienia`, `Radomyska Aneta`) z różnymi znacznikami czasu (`timestamp`) przez `ProviderScope` z nadpisanym `messagesProvider.overrideWith((ref) async => threads)` i `announcementsProvider.overrideWith((ref) async => const [])`, weryfikując przez `expect(find.text(...), findsOneWidget)`, że każda karta wyświetla właściwą datę swojej wiadomości.
  </action>
  <verify>
    <automated>flutter test test/presentation/screens/messages_timestamp_test.dart && flutter test test/message_attachments_test.dart</automated>
  </verify>
  <done>
    Wszystkie testy jednostkowe i widgetowe w `test/presentation/screens/messages_timestamp_test.dart` oraz istniejące testy wiadomości przechodzą bez błędów.
  </done>
</task>

</tasks>

<verification>
- `flutter analyze` przechodzi bez błędów.
- `flutter test test/presentation/screens/messages_timestamp_test.dart` przechodzi w 100%.
- `cd functions && npm test` przechodzi bez regresji.
</verification>

<success_criteria>
- Karty wiadomości w widoku `MessagesScreen` pokazują rzeczywistą datę i godzinę każdej wiadomości (`thread.formattedTimestamp`), a nie zahardkodowany tekst z makiety.
- Daty wiadomości są spójnie formatowane na ekranie Wiadomości oraz na Pulpicie (desktop i mobile).
- Nowe testy jednostkowe i widgetowe potwierdzają poprawne parsowanie i wyświetlanie dat.
</success_criteria>

<output>
After completion, create `.planning/quick/260930-dhq-wszystkie-wiadomo-ci-pokazuj-si-jakby-by/260930-dhq-SUMMARY.md`
</output>
