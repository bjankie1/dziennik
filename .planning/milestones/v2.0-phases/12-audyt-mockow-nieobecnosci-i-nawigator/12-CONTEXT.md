# Phase 12: Audyt mocków, nieobecności w planie lekcji i stała szerokość przełącznika tygodni - Context

**Gathered:** 2026-09-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Faza 12 realizuje 3 powiązane filary jakościowe i wizualne:
1. **Pełny audyt i eliminacja sztucznych mocków/fallbacków:** Całkowite odcięcie danych testowych z `MockData` w trybie zalogowania do konta Librus. Czyste stany puste i ukrywanie boksu sprawdzianu na Pulpicie przy pustym terminarzu.
2. **Naniesienie statusów frekwencji na plan lekcji:** Wyświetlanie statusu obecności/nieobecności (nieobecność, usprawiedliwiona, oczekująca na weryfikację, zwolnienie, spóźnienie) bezpośrednio na kafelkach lekcji w widoku tygodniowym (siatka), widoku dziennym (agenda) oraz w modalu szczegółów lekcji.
3. **Stała szerokość przełącznika tygodni w `WeekNavigatorBar`:** Przypięcie przycisków nawigacyjnych `[<]` i `[>]` do stałych pozycji w kontenerze o stałej szerokości (~420px na desktopie), aby wielokrotne klikanie strzałki w prawo nie przesuwało kursora myszy.

</domain>

<decisions>
## Implementation Decisions

### 1. Wizualna prezentacja nieobecności w planie lekcji
- **D-01:** Na kafelkach lekcji w siatce tygodniowej (`WeeklyGridView`) wyświetlana jest kompaktowa pigułka tekstowa ze statusem obok numeru sali (np. „Nieobecność”, „Usprawiedliwiona”, „Zwolnienie”, „Spóźnienie”).
- **D-02:** Nieobecność, dla której wysłano już e-usprawiedliwienie oczekujące na akceptację przez wychowawcę, ma dedykowaną bursztynową pigułkę „Oczekuje na weryfikację” (wyróżniającą ją od zwykłej czerwonej nieobecności).
- **D-03:** W widoku agendy dziennej (`AgendaLessonCard`) oraz w modalu szczegółów lekcji (`LessonDetailsModal`) prezentowany jest pełny blok informacyjny o frekwencji wraz z powodem podanym przez rodzica oraz statusem decyzji nauczyciela.

### 2. Polityka braku danych z Librusa (Empty State vs Mocki)
- **D-04:** Gdy uczeń nie ma w Librusie żadnego zaplanowanego sprawdzianu ani kartkówki, kafelek sprawdzianu na Pulpicie jest całkowicie ukrywany, a harmonogram dnia płynnie wypełnia kolumnę.
- **D-05:** W trybie zalogowania do konta Librus (`!isDemo`) obowiązuje bezwzględne odcięcie mocków z `MockData`: brak danych w danej kategorii (np. pusty plan lekcji na dzień wolny lub brak ocen) oznacza wyświetlenie estetycznego stanu pustego (np. „Brak zajęć w tym dniu”), a nie wstrzykiwanie danych testowych.

### 3. Zablokowanie stałej szerokości przełącznika tygodni
- **D-06:** Kontener wyboru tygodnia w `WeekNavigatorBar` ma stałą szerokość (~420px) na desktopie i tabletach. Przyciski `[<]` oraz `[>]` są przypięte do stałych krawędzi, a tekst zakresu dat oraz ewentualny badge „Aktualny tydzień” są wyśrodkowane w elastycznym kontenerze (`Expanded`) pomiędzy nimi.
- **D-07:** Zmiana długości tekstu daty oraz pojawianie się lub znikanie badge'a „Aktualny tydzień” nie przesuwa pozycji przycisku `[>]` ani o jeden piksel.
- **D-08:** Na ekranach węższych niż 500px (mobile) pasek elastycznie dopasowuje się do szerokości ekranu, aby uniknąć błędów overflow.

### 4. Ujednolicenie danych profilu ucznia
- **D-09:** Dane wychowawcy pobierane są bezpośrednio z profilu Librus (`data['student']['educator']`, np. `Sobota Łukasz`), dodawane do modelu `StudentProfile` oraz do listy `TeacherContact` z rolą `Wychowawca` i prezentowane we wszystkich nagłówkach oraz skrócie kontaktu zamiast sztywnego nazwiska `mgr K. Wiśniewski`.
- **D-10:** W dniach wolnych od nauki i weekendach, gdy Librus nie losuje szczęśliwego numerka, chip numerka wyświetla neutralną informację „Brak losowania w weekend” lub jest ukrywany zamiast wyświetlania sztucznej cyfry 9 czy 18.
- **D-11:** Wszelkie statyczne ciągi w widoku ocen (`Klasa 3B LO`, `Liceum Ogólnokształcące im. KEN`) są zastąpione dynamicznymi polami z `studentProfileProvider`.

### The Agent's Discretion
- Dokładny dobór odcieni kolorystycznych pigułek obecności zgodny z paletą systemu `AppColors` (czerwień `error` dla nieobecności, szmaragd `secondary` dla usprawiedliwionej, bursztyn `tertiary` dla oczekującej, błękit dla zwolnienia).
- Dokładna szerokość kontenera nawigatora tygodni (optymalnie 420px-440px) zapewniająca swobodny margines dla najdłuższych polskich nazw miesięcy (np. „28 Październik – 2 Listopad 2026”).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Plan Lekcji i Frekwencja
- `lib/domain/models/lesson_slot.dart` — Model slotu lekcyjnego i powiązanie z frekwencją.
- `lib/domain/models/attendance_record.dart` — Typy obecności `AttendanceType` i statusy `JustificationStatus`.
- `lib/data/repositories/firestore_school_repository.dart` — Pobieranie i łączenie danych planu i frekwencji.
- `lib/presentation/screens/schedule/widgets/weekly_grid_view.dart` — Siatka planu lekcji i renderowanie komórek.
- `lib/presentation/screens/schedule/widgets/agenda_lesson_card.dart` — Karta lekcji w widoku agendy.
- `lib/presentation/screens/schedule/widgets/week_navigator_bar.dart` — Pasek wyboru tygodnia.
- `lib/presentation/screens/schedule/widgets/lesson_details_modal.dart` — Modal ze szczegółami zajęć.

### Profil i Audyt Mocków
- `lib/domain/models/student_profile.dart` — Model profilu ucznia i wychowawcy.
- `lib/presentation/screens/dashboard/dashboard_screen.dart` — Pulpit, harmonogram, sprawdziany i szczęśliwy numerek.
- `lib/presentation/screens/grades/grades_screen.dart` — Nagłówki ocen i eliminacja KEN / 3B LO.
- `functions/src/librus_client.js` — Scraper danych Librus, obsługa szczęśliwego numerka i danych ucznia.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AttendanceType` i `JustificationStatus` w `lib/domain/models/attendance_record.dart` — gotowe enumy i struktura.
- `AppColors` — predefiniowane tokeny kolorystyczne dla stanów sukcesu, błędu, ostrzeżenia i informacji.

### Established Patterns
- Wzbogacanie planu lekcji: w `firestore_school_repository.dart` zaimplementowano już wzorzec łączenia zdarzeń z terminarza (`_extractAllEvents`) z lekcjami. Dokładnie ten sam mechanizm zostanie zastosowany dla frekwencji (`data['attendance']`).

### Integration Points
- `_parseTimetableForDay` w `firestore_school_repository.dart` — centralne miejsce konstrukcji obiektów `LessonSlot`.
- `WeeklyGridView._buildLessonCell` — komórka lekcji w siatce tygodniowej.
- `WeekNavigatorBar` — dolny rząd z selektorem tygodnia.

</code_context>

<specifics>
## Specific Ideas
- Użytkownik chce klikać przycisk „Następny tydzień” wielokrotnie bez przesuwania myszki — pozycja przycisku `>` musi być bezwzględnie nieruchoma w poziomie.
- Karta sprawdzianu na Pulpicie nie może pokazywać fikcyjnego sprawdzianu — gdy brak sprawdzianu w terminarzu, karta znika.

</specifics>

<deferred>
## Deferred Ideas
None — dyskusja skupiła się ściśle na zakresie Fazy 12.

</deferred>

---

*Phase: 12-audyt-mockow-nieobecnosci-i-nawigator*
*Context gathered: 2026-09-20*
