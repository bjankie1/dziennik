# Phase 23: Podgląd szczegółów próśb o usprawiedliwienie i oczekujących wniosków - Context

**Gathered:** 2026-10-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Umożliwienie rodzicowi i uczniowi przejrzystego podglądu, czego dokładnie dotyczą:
1. **Prośby o usprawiedliwienie od ucznia** wyświetlane na żółtym banerze na Pulpicie (desktop/mobile) oraz na ekranie Frekwencji (gdzie obecnie widnieje jedynie liczba lekcji i powód, np. „6 lekcji • Choroba”).
2. **Oczekujące wnioski do wychowawcy** wyświetlane na banerze „X wnioski czekają na wychowawcę” na ekranie Frekwencji (które przy domyślnym filtrze „Do usprawiedliwienia” są niewidoczne na liście poniżej).

</domain>

<decisions>
## Implementation Decisions

### 1. Podgląd szczegółów prośby o usprawiedliwienie (Pulpit i Frekwencja)
- **D-01:** Kliknięcie w żółty baner prośby o usprawiedliwienie (zarówno na Pulpicie w `dashboard_mobile_view.dart` i `dashboard_metrics_column.dart`, jak i na ekranie Frekwencji w `attendance_screen.dart`) otwiera dedykowany modal szczegółów prośby (`ParentApprovalModal`) prezentujący szczegółową listę wszystkich objętych lekcji wraz z akcjami **Zatwierdź (PIN)** oraz **Odrzuć**.
- **D-02:** Na samym banerze prośby (obok liczby lekcji i powodu, np. `6 lekcji • Choroba`) dodana zostaje czytelna wskazówka wizualna (np. zakres dat / link `Zobacz szczegóły →`), aby użytkownik widział, że baner jest interaktywny i otwiera podgląd lekcji.
- **D-03:** Przy tworzeniu prośby o usprawiedliwienie (`requestJustification` w `firestore_school_repository.dart`) oraz przy wyświetlaniu banera należy używać imienia i nazwiska ucznia z profilu ucznia (`Oskar Jankiewicz`), a nie `appUser.displayName` zalogowanego konta Google rodzica (gdy rodzic testowo przełącza rolę na ucznia).

### 2. Zakres szczegółów pojedynczej lekcji i częściowa akceptacja w modalu
- **D-04:** Modal szczegółów i autoryzacji prośby (`ParentApprovalModal`) rozwiązuje powiązane `recordIds` (oraz fallback po `date` + `lessonNumbers`) względem pełnej listy rekordów `AttendanceRecord` z `attendanceProvider`.
- **D-05:** Lekcje w modalu są pogrupowane dniami (z nagłówkiem dnia: **Data i dzień tygodnia**, np. *Wtorek, 29 Września 2026*), a każdy wiersz lekcji prezentuje:
  - **Nr lekcji + godziny** (np. `Lekcja 3 • 09:45–10:30`),
  - **Przedmiot** (np. `Język polski`),
  - **Nauczyciel** (oraz sala, jeśli dostępna),
  - **Powód / uzasadnienie ucznia** (oraz historię dialogu Q&A, jeśli prośba była wcześniej odrzucana/komentowana).
- **D-06:** Przy każdej lekcji w modalu `ParentApprovalModal` znajduje się checkbox (domyślnie wszystkie lekcje z prośby są zaznaczone). Rodzic może odznaczyć wybrane lekcje przed zatwierdzeniem PIN-em — wówczas do Librusa wysyłane są wyłącznie zaznaczone lekcje (częściowa akceptacja prośby), a przycisk zatwierdzania dynamicznie pokazuje liczbę wybranych lekcji (np. `Zatwierdź z PIN-em (5 z 6 lekcji)`).

### 3. Podgląd i zarządzanie „X wnioski czekają na wychowawcę” (Frekwencja)
- **D-07:** Baner `X wnioski czekają na wychowawcę` w `AttendanceScreen` staje się rozwijany (akordeon / sekcja rozwijana po kliknięciu w baner lub przycisk `Pokaż szczegóły`). Po rozwinięciu wyświetla pogrupowaną dniami listę wszystkich lekcji ze statusem `JustificationStatus.requested` (Data i dzień tygodnia, Nr lekcji + godziny, Przedmiot, Nauczyciel, wysłany powód usprawiedliwienia).
- **D-08:** W rozwiniętej liście oczekujących wniosków użytkownik może cofnąć **pojedynczy wniosek** (przycisk `Cofnij` przy danej lekcji) lub **wszystkie oczekujące wnioski** naraz (`Cofnij wszystkie`).
- **D-09:** Na pasku filtrów w `AttendanceScreen` obok `Wszystkie`, `Do usprawiedliwienia (X)` oraz `Usprawiedliwione` dodana zostaje czwarta pigułka filtra: **`Oczekujące (Y)`** (gdzie `Y` to liczba lekcji ze statusem `JustificationStatus.requested`), pozwalająca jednym kliknięciem wyfiltrować główną listę frekwencji do samych oczekujących wniosków.

### the agent's Discretion
- Dokładna stylistyka mikro-animacji rozwijania banera `X wnioski czekają na wychowawcę` (`AnimatedCrossFade` / `AnimatedSize`) zgodnie z paletą `AppColors` i bursztynową kolorystyką statusu oczekującego (`#FFFBEB` / `#D97706`).
- Sposób przekazania zawężonej listy `selectedRecordIds` podczas częściowej akceptacji w `approveJustification` (aktualizacja `recordIds` na dokumencie prośby lub przekazanie wybranych ID do `approveJustificationRequest`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & State
- `.planning/ROADMAP.md` — Definicja Fazy 23 i kryteria sukcesu
- `.planning/STATE.md` — Aktualny stan projektu i historia powiązanych zadań z modułu frekwencji

### Attendance & Justification Models and Screens
- `lib/domain/models/justification_request.dart` — Model `JustificationRequest` (`recordIds`, `lessonNumbers`, `subjectNames`, `date`, `reason`, `dialogHistory`)
- `lib/domain/models/attendance_record.dart` — Model `AttendanceRecord` (`id`, `date`, `lessonNumber`, `subjectName`, `timeSlot`, `teacherName`, `classroom`, `justificationStatus`, `justificationReason`)
- `lib/presentation/screens/attendance/attendance_screen.dart` — Ekran Frekwencji z banerem prośby ucznia, banerem „X wnioski czekają na wychowawcę” oraz paskiem filtrów
- `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart` — Modal autoryzacji PIN-em i podglądu prośby ucznia
- `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` — Baner prośby o usprawiedliwienie na Pulpicie (widok mobilny / pośredni)
- `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` — Karta prośby o usprawiedliwienie na Pulpicie desktopowym
- `lib/data/repositories/firestore_school_repository.dart` — Logika `requestJustification`, `approveJustificationRequest`, `submitJustification`, `cancelJustification` oraz `getJustificationRequests`
- `functions/index.js` — Endpointy Cloud Functions `createJustificationRequest` i `reviewJustificationRequest`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ParentApprovalModal` (`lib/presentation/screens/attendance/widgets/parent_approval_modal.dart`): Istniejący modal dolny (bottom sheet) z obsługą 4-cyfrowego PIN-u i przekierowaniem do `ParentRejectionModal`. Może przyjmować opcjonalną listę rozwiązanych `AttendanceRecord` lub samodzielnie pobierać je przez `ConsumerStatefulWidget` (`ref.watch(attendanceProvider)`).
- `_formatDayHeader(DateTime)` w `AttendanceScreen`: Gotowe polskie formatowanie nagłówka dnia (`Wtorek, 1 Września 2026`).
- `attendanceProvider.notifier.cancelJustification(List<String> ids)`: Gotowa metoda pozwalająca wycofać zarówno wszystkie ID (`pendingList.map((r) => r.id).toList()`), jak i pojedyncze ID (`[record.id]`).

### Established Patterns
- Karty dni w `AttendanceScreen` grupują lekcje po kluczu `yyyy-MM-dd` i wyświetlają czytelne wiersze z numerem lekcji, przedmiotem, godzinami `timeSlot`, salą i nauczycielem.
- `ParentApprovalModal` stosuje stały nagłówek, przewijaną sekcję środkową (`Flexible` + `SingleChildScrollView`) oraz przypięte na dole przyciski akcji (naprawione w quick tasku `260929-jas`).

### Integration Points
- `AttendanceNotifier.approveJustification(String requestId, String pin, {List<String>? selectedRecordIds})`: rozszerzenie o opcjonalną listę zaznaczonych `recordIds`, aby częściowa akceptacja usprawiedliwiała tylko wybrane przez rodzica godziny.
- `AttendanceScreen._activeFilter`: obsługa nowego filtra dla oczekujących wniosków (`JustificationStatus.requested`) obok `Wszystkie`, `Do usprawiedliwienia` i `Usprawiedliwione`.

</code_context>

<specifics>
## Specific Ideas

- Gdy rodzic widzi baner „prosi o usprawiedliwienie • 6 lekcji • Choroba”, kliknięcie w dowolne miejsce banera otwiera modal ze szczegółową listą 6 lekcji pogrupowanych dniami, gdzie każda lekcja ma checkbox (domyślnie zaznaczony) i pełne dane (Data i dzień tygodnia, Nr lekcji + godziny, Przedmiot, Nauczyciel, Powód).
- Gdy rodzic lub uczeń widzi na ekranie Frekwencji baner „7 wnioski czekają na wychowawcę”, może kliknąć w ten baner, aby rozwinąć podgląd tych 7 lekcji pogrupowanych dniami (z opcją cofnięcia pojedynczej lekcji lub wszystkich), albo przełączyć się na pigułkę filtra `Oczekujące (7)`.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni*
*Context gathered: 2026-10-02*
