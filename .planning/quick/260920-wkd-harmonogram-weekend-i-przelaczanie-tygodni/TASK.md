# Szybkie Zadanie: Harmonogram na weekend oraz dynamiczne przełączanie tygodni w planie lekcji

**ID:** 260920-wkd  
**Data:** 2026-09-20  
**Status:** Wykonane  

## Zgłoszone problemy
1. **Pulpit w weekend (Niedziela):** Na pulpicie wyświetlał się harmonogram lekcji na dziś, mimo że dzisiaj jest niedziela (fałszywy fallback do 6 lekcji mockowych, komunikat "1 / 6 zrealizowane", "Początek lekcji: 08:00").
2. **Przełączanie tygodni w planie lekcji:** Zmiana tygodnia w `ScheduleScreen` nie odświeżała danych z repozytorium – po przejściu na przyszły tydzień lekcje od środy do piątku nadal były oznaczone jako odwołane z powodu wycieczki do Warszawy (która miała miejsce wyłącznie w dniach 14-18 września 2026).

## Wprowadzone zmiany

### 1. `lib/data/repositories/firestore_school_repository.dart`
- Dodano metody pomocnicze `_normalizeToMonday(DateTime dt)` oraz `_isWarsawTripWeek(DateTime date)`, która zwraca `true` wyłącznie dla poniedziałku wycieczki: `2026-09-14`.
- Zaktualizowano `_parseTimetableForDay(rawList, targetDay, {DateTime? weekStart})`:
  - Izolacja flagi `isCancelled`: odwołania wycieczkowe obowiązują wyłącznie w tygodniu wycieczki (`isTripWeek && rawCancelled`).
  - W pozostałych tygodniach (w tym przyszły tydzień 21-25 września 2026) lekcje są normalne (`LessonStatus.normal`, `statusNote: null`), a ewentualne prefiksy "odwołane" są usuwane z nazwy przedmiotu.
- W `getTodaySchedule()`:
  - W sobotę i niedzielę (`now.weekday == 6 || now.weekday == 7`) natychmiast zwracana jest pusta lista `[]`. Zlikwidowano fałszywy fallback do mocków w dni wolne.
- W `getScheduleForDay(dayOfWeek)`:
  - Dla dni weekendowych (> 5) zwracane `[]`.
- W `getWeekSchedule({DateTime? weekStart})`:
  - Przekazywanie `effectiveWeekStart` do `_parseTimetableForDay`, dzięki czemu każde przełączenie tygodnia poprawnie przelicza statusy lekcji dla danego tygodnia.

### 2. `lib/data/repositories/mock_school_repository.dart`
- `getTodaySchedule()`: zwraca `[]` w soboty i niedziele.
- `getScheduleForDay(dayOfWeek)`: zwraca `[]` dla sobót i niedziel.
- `getWeekSchedule({DateTime? weekStart})`: czyści status odwołania, jeśli wybrany tydzień nie jest tygodniem wycieczki (14-18.09.2026).

### 3. `lib/domain/models/lesson_slot.dart`
- Dodano metodę `copyWith(...)` do modelu `LessonSlot`.

### 4. `lib/presentation/providers/school_providers.dart`
- Utworzono `SelectedWeekMondayNotifier` oraz `selectedWeekMondayProvider` z metodami `previousWeek()`, `nextWeek()`, `resetToCurrentWeek()`, `setMonday()`.
- Zaktualizowano `weekScheduleProvider`: nasłuchuje `selectedWeekMondayProvider` i wywołuje `repo.getWeekSchedule(weekStart: monday)`.
- Zaktualizowano `weeklyScheduleStatsProvider`: w stanie ładowania zwraca zerowe statystyki zamiast sztywnych mockowych wartości.

### 5. `lib/presentation/screens/schedule/schedule_screen.dart`
- Zastąpiono lokalny stan `_currentWeekMonday` powiązaniem z `ref.watch(selectedWeekMondayProvider)`.
- Metody nawigacji paska tygodnia przekazują akcje do `ref.read(selectedWeekMondayProvider.notifier)`.

### 6. `lib/presentation/screens/dashboard/dashboard_screen.dart`
- **Desktop:**
  - W banerze powitalnym: gdy jest weekend lub brak lekcji (`isWeekend || !hasLessons`), zamiast godzin rozpoczęcia i zakończenia wyświetla się elegancki podpis: `Weekend • Dzień wolny od zajęć lekcyjnych 🎉`.
  - W kolumnie harmonogramu: plakietka statusu pokazuje `Weekend` (lub `Dzień wolny`) zamiast `X / Y zrealizowane`. Wyświetlana jest estetyczna karta weekendowa z ikoną `Icons.weekend_rounded` i informacją o odpoczynku oraz przycisk przejścia do pełnego planu lekcji.
- **Mobile:**
  - Karta planu zajęć wyświetla chip `Weekend` oraz kartę wolnego dnia z zachętą do odpoczynku i przyciskiem przejścia do pełnego planu lekcji.
