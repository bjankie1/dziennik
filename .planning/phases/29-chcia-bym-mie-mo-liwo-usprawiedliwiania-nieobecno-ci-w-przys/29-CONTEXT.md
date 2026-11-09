# Phase 29: Usprawiedliwianie nieobecności w przyszłości (wyprzedzające wnioski o usprawiedliwienie) - Context

**Gathered:** 2026-11-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Umożliwienie zgłaszania i usprawiedliwiania nieobecności z wyprzedzeniem na przyszłe dni oraz wielodniowe zakresy dat (np. podczas wyjazdu wakacyjnego za cały bieżący tydzień wraz z kolejnym poniedziałkiem):
1. **Rozbudowa modali usprawiedliwiania (`JustificationModal` dla Rodzica i `StudentJustificationModal` dla Ucznia)** o dwa osobne pola kalendarzowe **„Data od”** i **„Data do”**, pigułki szybkiego wyboru okresów (`Dzisiaj`, `Jutro`, `Obecny tydzień (Pn–Pt)`, `Obecny tydzień + poniedziałek`, `Przyszły tydzień`) oraz szybki powód **„Wyjazd rodzinny”**.
2. **Stały punkt wejścia na ekranie Frekwencji (`AttendanceFilterBar`)** otwierający modal od razu w trybie wyboru zakresu dat (`Data od = dzisiaj`, `Data do = dzisiaj`), bez automatycznego podpinania zaległych nieobecności z przeszłości (oraz ujednolicenie Szybkiej Akcji na Pulpicie).
3. **Pełny obieg prośby ucznia i zatwierdzania przez rodzica dla przyszłych zakresów dat** — obsługa `dateFrom` / `dateTo` w modelu `JustificationRequest` i Cloud Functions (`createJustificationRequest`, `reviewJustificationRequest`), prezentacja przyszłych dni szkolnych wraz z planowanymi lekcjami z planu lekcji w `ParentApprovalModal`, wysyłka w trybie całodniowym `wgDat` (`dataOd`–`dataDo`) do Librus Synergia oraz zabezpieczenie przed przedwczesnym auto-zamykaniem przyszłych próśb.
4. **Prezentacja wysłanych przyszłych usprawiedliwień we Frekwencji i Planie lekcji** — widoczność przyszłych zgłoszonych dni/lekcji w zakładce **`Oczekujące (Y)`** i rozwijanym banerze **„X wnioski czekają na wychowawcę”** (`PendingTeacherAccordionBanner`) z możliwością wycofania (`Cofnij` / `Cofnij wszystkie`), ochrona bieżącego procentu frekwencji (`AttendanceSemesterKpiCard`) przed sztucznym spadkiem dla przyszłych dni oraz oznaczenie kafelków w **Planie lekcji** plakietką **„Zgłoszona nieobecność”** / **„Usprawiedliwione”**.

</domain>

<decisions>
## Implementation Decisions

### 1. Wybór zakresu dat i szybkie skróty w modalach (`JustificationModal` & `StudentJustificationModal`)
- **D-01 (Dwa osobne pola „Data od” i „Data do” + szybkie pigułki):** W `JustificationModal` oraz `StudentJustificationModal` zastępujemy pojedyncze pole daty dwoma czytelnymi polami kalendarzowymi **„Data od”** (`dateFrom`) i **„Data do”** (`dateTo`), z których każde otwiera `showDatePicker` (z automatycznym pilnowaniem, aby `dateTo >= dateFrom`).
- **D-02 (Zestaw pigułek szybkiego wyboru nad polami dat):** Nad polami `Data od` i `Data do` umieszczamy poziomy pasek pigułek (chips) automatycznie wypełniających oba pola jednym kliknięciem:
  - **`Dzisiaj`** (`dateFrom = dziś`, `dateTo = dziś`),
  - **`Jutro`** (`dateFrom = jutro`, `dateTo = jutro`),
  - **`Obecny tydzień (Pn–Pt)`** (poniedziałek–piątek bieżącego tygodnia),
  - **`Obecny tydzień + poniedziałek`** (poniedziałek bieżącego tygodnia – poniedziałek kolejnego tygodnia),
  - **`Przyszły tydzień (Pn–Pt)`** (poniedziałek–piątek kolejnego tygodnia).
  Po kliknięciu dowolnej pigułki użytkownik może dodatkowo ręcznie skorygować `Data od` lub `Data do`.
- **D-03 (Szybki powód „Wyjazd rodzinny”):** Lista szybkich powodów (`_quickReasons` w `StudentJustificationModal`, `FloatingJustificationDock` oraz `JustificationModal`) zostaje rozszerzona o chip **„Wyjazd rodzinny”** (obok `Choroba`, `Wizyta lekarska`, `Złe samopoczucie`, `Sprawy rodzinne`, `Zawody sportowe`).
- **D-04 (Obsługa weekendów w wielodniowym zakresie dat):** Gdy zakres `dateFrom` – `dateTo` przechodzi przez weekend (np. poniedziałek `09.11` – poniedziałek `16.11`), w podglądzie dni/lekcji wewnątrz aplikacji automatycznie pomijane są dni weekendowe (`Sobota`, `Niedziela`), tak aby licznik i lista pokazywały rzeczywiste dni szkolne (np. `6 dni szkolnych`), natomiast do formularza Librus Synergia (`/eusprawiedliwienia/dodaj`) wysyłany jest zakres `dataOd` – `dataDo` w trybie `wgDat`.

### 2. Punkt wejścia w UI (`AttendanceFilterBar` & `DashboardScreen`)
- **D-05 (Stały przycisk w pasku nagłówka sekcji na ekranie Frekwencji):** W `AttendanceFilterBar` (w wierszu nagłówka `Zgłoszenia nieobecności` na `AttendanceScreen`) dodajemy stały, widoczny niezależnie od zaznaczenia checkboxów przycisk otwierający modal zgłaszania nieobecności po dacie/zakresie dat:
  - Dla roli **Rodzica (`!isStudent`)**: **`Zgłoś nieobecność`** (z ikoną `Icons.event_busy_outlined` / `Icons.date_range_rounded`), otwierający `JustificationModal`.
  - Dla roli **Ucznia (`isStudent`)**: **`Poproś o usprawiedliwienie`**, otwierający `StudentJustificationModal`.
- **D-06 (Tryb wyboru zakresu dat bez podpinania starych zaległości):** Otwarcie modalu z przycisku w `AttendanceFilterBar` lub z Szybkiej Akcji na Pulpicie (`dashboard_metrics_column.dart`) przekazuje pustą listę `selectedRecordIds: const []` i domyślnie inicjalizuje `Data od = dzisiaj`, `Data do = dzisiaj` (zamiast automatycznego podpinania wszystkich historycznych nieusprawiedliwionych godzin, które są usprawiedliwiane przez zaznaczenie checkboxów i `FloatingJustificationDock`).
- **D-07 (Brak dodatkowego przycisku w nagłówku Planu lekcji):** Na ekranie Planu lekcji (`ScheduleScreen`) nie dodajemy kolejnego przycisku w pasku nawigacji tygodnia — wystarczają ekran Frekwencji, Szybka Akcja na Pulpicie oraz istniejący przycisk w `LessonDetailsModal`.

### 3. Obieg prośby ucznia i zatwierdzania przez rodzica dla przyszłych dat
- **D-08 (Wsparcie `dateFrom` i `dateTo` w prośbach ucznia):** Model `JustificationRequest`, metoda `FirestoreJustificationsDataSource.requestJustification` oraz backendowy walidator `sanitizeStudentRequest` w `functions/src/justification_service.js` obsługują zakres dat `dateFrom` i `dateTo` (`YYYY-MM-DD`). Gdy podano `dateFrom` (lub `date`), backend nie wymaga niepustej tablicy `recordIds` (ponieważ dla przyszłych dni nie istnieją jeszcze rekordy nieobecności w Librusie).
- **D-09 (Prezentacja przyszłych dni i planowanych lekcji w banerze i `ParentApprovalModal`):**
  - Na żółtym banerze `JustificationRequestBanner` (Pulpit i Frekwencja) dla wniosku zakresowego wyświetlana jest zwięzła informacja o zakresie dat i liczbie dni szkolnych (np. `09.11–16.11 (6 dni) • Wyjazd rodzinny`).
  - W modalu zatwierdzania `ParentApprovalModal` (`requested_attendance_details_sheet.dart` / `justification_approval_dialogs.dart`), jeśli dla dni z zakresu `dateFrom`–`dateTo` nie ma jeszcze wpisów `AttendanceRecord`, lista dni szkolnych (Pn–Pt) oraz przypisanych do nich lekcji jest dynamicznie budowana na podstawie planu lekcji ucznia (`timetable` / `LessonSlot`). Rodzic widzi konkretne dni i lekcje oraz może odznaczyć wybrane dni/lekcje przed zatwierdzeniem PIN-em.
- **D-10 (Wysyłka „wgDat” do Librus Synergia i ochrona przed auto-zamknięciem prośby):**
  - Zatwierdzenie przez rodzica (lub bezpośrednie wysłanie przez `submitJustification`) przyszłego zakresu całodniowego wysyła wniosek do Librusa w trybie całodniowym `isByHours: false` (`datyLubLekcje: "wgDat"`, `dataOd`, `dataDo`; a w razie odznaczenia wybranych dni ze środka zakresu — odpowiednie ciągłe przedziały dat lub godziny).
  - Logika rekonsyliacji w `FirestoreJustificationsDataSource.getJustificationRequests()` nie zamyka automatycznie (`approved`) prośby `pendingParentApproval`, która dotyczy przyszłych dat / zakresu dat (`recordIds.isEmpty` lub `dateTo >= today`), dopóki rodzic nie zatwierdzi/odrzuci jej ręcznie lub dopóki w Librus `/eusprawiedliwienia` nie pojawi się pokrywający wniosek.

### 4. Prezentacja wysłanych przyszłych usprawiedliwień we Frekwencji i Planie lekcji
- **D-11 (Widoczność w „Oczekujące (Y)” i banerze wychowawcy z obsługą „Cofnij”):** Po wysłaniu wyprzedzającego usprawiedliwienia (lub zatwierdzeniu prośby ucznia na przyszły okres) przyszłe dni szkolne i lekcje objęte wnioskiem (zapisane w lokalnych/Firestore overrides oraz powiązane z `/eusprawiedliwienia` w Librusie) są widoczne w sekcji **`Oczekujące (Y)`** oraz w rozwijanym banerze **„X wnioski czekają na wychowawcę”** (`PendingTeacherAccordionBanner`), z pełną obsługą przycisku **`Cofnij`** (dla pojedynczej pozycji) i **`Cofnij wszystkie`**.
- **D-12 (Ochrona semestralnego wykresu frekwencji `AttendanceSemesterKpiCard`):** Syntetyczne/przyszłe pozycje oczekujące lub usprawiedliwione (dla dat późniejszych niż dzisiejsza lub nieposiadających jeszcze wpisu nieobecności od nauczyciela w Librusie) **nie są doliczane** do mianownika `totalLessons` ani licznika `totalAbsences` w `AttendanceSemesterKpiCard`, dzięki czemu wysłanie wyprzedzającego wniosku na wakacje nie powoduje sztucznego spadku procentu frekwencji przed nastąpieniem tych dni.
- **D-13 (Plakietki w Planie lekcji dla przyszłych usprawiedliwionych dni):** Kafelki lekcji w widoku **Planu lekcji** (`ScheduleScreen` — siatka i agenda) dla przyszłych/bieżących dni objętych wysłanym usprawiedliwieniem wyświetlają plakietkę statusu (**„Zgłoszona nieobecność”** / `Oczekujące` przed akceptacją wychowawcy oraz **„Usprawiedliwione”** po akceptacji).

### the agent's Discretion
- Dokładny układ wizualny pigułek szybkiego wyboru okresu (`Dzisiaj`, `Jutro`, `Obecny tydzień`, `Obecny tydzień + poniedziałek`, `Przyszły tydzień`) oraz dwóch pól `Data od` i `Data do` w `JustificationModal` i `StudentJustificationModal`.
- Sposób przechowywania wyprzedzających zakresów usprawiedliwień w `SchoolDataCacheManager` / Firestore (np. mapa zakresów dat lub syntetyczne klucze `future_YYYY-MM-DD_lessonN`), tak aby bezproblemowo współpracowały z `cancelJustification` (`Cofnij`) oraz z rzeczywistymi wpisami z Librusa, gdy nauczyciele zaczną wpisywać nieobecności.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & State
- `.planning/ROADMAP.md` — Definicja Fazy 29
- `.planning/STATE.md` — Aktualny stan projektu i decyzje z Faz 14, 21, 23, 24, 25

### Modals & Attendance UI
- `lib/presentation/screens/attendance/justification_modal.dart` — Modal autoryzacji e-Usprawiedliwienia z PIN-em dla rodzica (rozbudowa o `Data od` / `Data do`, pigułki okresów i szybkie powody)
- `lib/presentation/screens/attendance/widgets/student_justification_modal.dart` — Modal prośby o usprawiedliwienie dla ucznia (rozbudowa o `Data od` / `Data do`, pigułki okresów i powód `Wyjazd rodzinny`)
- `lib/presentation/screens/attendance/attendance_screen.dart` — Główny ekran Frekwencji, kalkulacja KPI (`AttendanceSemesterKpiCard`) i filtrowanie rekordów
- `lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart` — Pasek filtrów i nagłówek `Zgłoszenia nieobecności` (dodanie przycisku `Zgłoś nieobecność` / `Poproś o usprawiedliwienie`)
- `lib/presentation/screens/attendance/widgets/pending_teacher_accordion_banner.dart` — Rozwijany baner „X wnioski czekają na wychowawcę” z akcjami `Cofnij` i `Cofnij wszystkie`
- `lib/presentation/widgets/common/justification_request_banner.dart` — Baner prośby ucznia na Pulpicie i we Frekwencji
- `lib/presentation/widgets/common/justification_approval_dialogs.dart` — Modal zatwierdzania prośby ucznia przez rodzica (`ParentApprovalModal`)
- `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` — Szybka Akcja „Zgłoś nieobecność” / „Poproś o usprawiedliwienie” na Pulpicie

### Domain Models, Data Sources & Timetable Integration
- `lib/domain/models/justification_request.dart` — Model `JustificationRequest` (rozszerzenie o `dateFrom` / `dateTo` i rozwiązywanie dni/lekcji dla przyszłych dat)
- `lib/domain/models/attendance_record.dart` — Model `AttendanceRecord`
- `lib/data/repositories/firestore/firestore_justifications_data_source.dart` — Obsługa `requestJustification`, `getJustificationRequests`, `approveJustificationRequest`
- `lib/data/repositories/firestore/firestore_attendance_data_source.dart` — Pobieranie `AttendanceRecord`, nakładanie nadpisań (`cacheManager`), parsowanie `justifications` z Librusa (`period` zakresowy `YYYY-MM-DD - YYYY-MM-DD`) oraz `submitJustification`
- `lib/data/repositories/firestore/school_data_cache_manager.dart` — Zarządzanie lokalnymi i chmurowymi nadpisaniami usprawiedliwień
- `lib/presentation/screens/schedule/schedule_screen.dart` — Prezentacja statusów frekwencji / zgłoszonej nieobecności na kafelkach planu lekcji

### Backend (Cloud Functions)
- `functions/src/justification_service.js` — Walidacja `sanitizeStudentRequest`, `processParentReview` oraz `formatLibrusJustificationPayload` (obsługa `dateFrom`, `dateTo`, `isByHours: false` dla zakresów dat bez `recordIds`)
- `functions/src/librus_client.js` — `submitJustification` (`/eusprawiedliwienia/dodaj` w trybie `wgDat` oraz `wgGodzin`) i `fetchJustifications`
- `functions/index.js` — Endpointy `submitJustification`, `createJustificationRequest`, `reviewJustificationRequest`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LibrusClient.submitJustification` (`functions/src/librus_client.js` linie 1101–1135): Posiada już gotową gałąź `else` wysyłającą formularz `/eusprawiedliwienia/dodaj` z `datyLubLekcje = "wgDat"`, `dataOd = dateFrom` i `dataDo = dateTo || dateFrom`.
- `PolishDateFormatter` (`lib/core/utils/polish_date_formatter.dart`): Gotowe narzędzie do formatowania nagłówków dni i zakresów dat po polsku.
- `PendingTeacherAccordionBanner` (`lib/presentation/screens/attendance/widgets/pending_teacher_accordion_banner.dart`): Gotowy rozwijany baner grupujący pozycje `JustificationStatus.requested` po dniach z przyciskami `Cofnij` i `Cofnij wszystkie`.

### Established Patterns
- W `FirestoreAttendanceDataSource.getAttendanceRecords()` istnieje już słownik `rawTimetable = data['timetable']` oraz funkcja `lookupTimetableSlot(weekday, lessonNum, subjectName)`, co pozwala łatwo wygenerować planowane lekcje dla dowolnego przyszłego dnia szkolnego (Pn–Pt) objętego wysłanym zakresem usprawiedliwienia.
- W `FirestoreAttendanceDataSource` wiersze 202–225 parsują tablicę `rawJustifications` z Librusa (`/eusprawiedliwienia`) — obecnie sprawdzają `period.contains(dateStr)`, co warto rozszerzyć o obsługę przedziałów dat `YYYY-MM-DD - YYYY-MM-DD` (lub `DD.MM.YYYY - DD.MM.YYYY`), aby wielodniowe wnioski z Librusa automatycznie mapowały się na każdy dzień z przedziału.

### Integration Points
- `SchoolRepository` i `AttendanceNotifier` (`lib/presentation/providers/school_providers.dart`): Rozszerzenie `submitJustification` i `requestJustification` o opcjonalne parametry `DateTime? dateFrom, DateTime? dateTo` (z zachowaniem kompatybilności wstecznej dla `date`).
- `AttendanceScreen`: Odfiltrowanie przyszłych syntetycznych rekordów (daty `> dzisiaj` lub flaga syntetycznego zgłoszenia wyprzedzającego) z wyliczeń `totalLessons` / `totalAbsences` w `AttendanceSemesterKpiCard`, przy jednoczesnym zachowaniu ich w `pendingList` (`Oczekujące`) i `excusedList` (`Usprawiedliwione`).

</code_context>

<specifics>
## Specific Ideas

- Scenariusz główny użytkownika: „Teraz jesteśmy na wakacjach i chciałbym wysłać prośbę o usprawiedliwienie za cały obecny tydzień razem z przyszłym poniedziałkiem” — jedno kliknięcie w pigułkę **`Obecny tydzień + poniedziałek`** (lub kliknięcie `Obecny tydzień` i zmiana `Data do` na przyszły poniedziałek), wybór chipu **`Wyjazd rodzinny`** i wysłanie prośby / wniosku z PIN-em.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 29-chcia-bym-mie-mo-liwo-usprawiedliwiania-nieobecno-ci-w-przys*
*Context gathered: 2026-11-09*
