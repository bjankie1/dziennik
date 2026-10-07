---
phase: 261007-9as-sprawd-i-napraw-automatyczne-od-wie-anie
plan: 01
subsystem: schedule-and-dashboard-ui
tags: [schedule, dashboard, riverpod, live-progress, timer, app-lifecycle]
dependency_graph:
  requires: []
  provides:
    - "Time-aware LessonSlot helpers (startDateTimeOn, endDateTimeOn, isHappeningAt, isCompletedAt, progressAt, remainingMinutesAt)"
    - "Reactive CurrentTimeNotifier (currentTimeProvider) with 15-second periodic refresh and AppLifecycleListener resume/show refresh"
    - "Live-updating lesson progress bar, remaining minutes, completed count, and status badges across Desktop/Mobile Dashboard and Schedule views"
  affects:
    - "lib/domain/models/lesson_slot.dart"
    - "lib/data/mock/mock_data.dart"
    - "lib/presentation/providers/school_providers.dart"
    - "lib/presentation/screens/dashboard/dashboard_screen.dart"
    - "lib/presentation/screens/dashboard/widgets/dashboard_schedule_column.dart"
    - "lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart"
    - "lib/presentation/screens/schedule/widgets/agenda_view.dart"
    - "lib/presentation/screens/schedule/widgets/agenda_lesson_card.dart"
    - "lib/presentation/screens/schedule/widgets/weekly_grid_view.dart"
    - "lib/presentation/screens/schedule/widgets/lesson_details_modal.dart"
tech-stack:
  added: []
  patterns:
    - "Centralized Riverpod clock notifier (currentTimeProvider) with 15s Timer.periodic and AppLifecycleListener(onResume, onShow)"
    - "Pure domain time calculations on LessonSlot independent of static LessonStatus.inProgress"
key-files:
  created:
    - "test/presentation/screens/schedule_live_progress_test.dart"
  modified:
    - "lib/domain/models/lesson_slot.dart"
    - "lib/data/mock/mock_data.dart"
    - "lib/presentation/providers/school_providers.dart"
    - "lib/presentation/screens/dashboard/dashboard_screen.dart"
    - "lib/presentation/screens/dashboard/widgets/dashboard_schedule_column.dart"
    - "lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart"
    - "lib/presentation/screens/schedule/widgets/agenda_view.dart"
    - "lib/presentation/screens/schedule/widgets/agenda_lesson_card.dart"
    - "lib/presentation/screens/schedule/widgets/weekly_grid_view.dart"
    - "lib/presentation/screens/schedule/widgets/lesson_details_modal.dart"
decisions:
  - "Centralized live clock ticks in CurrentTimeNotifier (15s interval + AppLifecycleListener onResume/onShow) guarded by WidgetsBinding.instance is WidgetsFlutterBinding so FakeAsync widget tests never leak pending timers"
  - "Computed live lesson state (isHappeningAt, isCompletedAt, progressAt, remainingMinutesAt) directly from HH:mm startTime/endTime and lessonDate on LessonSlot so real Firestore/Librus lessons (which carry LessonStatus.normal or substituted) transition automatically between PLANOWO, W TRAKCIE, and ZREALIZOWANO"
metrics:
  duration: 13 min
  completed_date: "2026-10-07"
  tasks: 2
  files: 11
  commits: 2
  plan_head_before: bd685b631466cf863d810bf0ee8101a68797eea8
  plan_head_after: 208b332b080abe0f7d4c89128ff1b4e86585c850
status: complete
---

# Quick Task 261007-9as: Sprawdź i napraw automatyczne odświeżanie paska czasu lekcji Summary

Reaktywny zegar `currentTimeProvider` (odświeżany co 15 sekund oraz natychmiast po powrocie na kartę przeglądarki / wznowieniu aplikacji) połączony z metodami czasowymi `LessonSlot`, zapewniający płynne przesuwanie paska postępu (`LinearProgressIndicator`), odliczanie pozostałych minut oraz automatyczną zmianę statusu i kolorystyki lekcji (`PLANOWO` → `W TRAKCIE` → `ZREALIZOWANO`) bez przeładowania strony.

## Diagnoza problemu

1. **Jednorazowy odczyt `DateTime.now()` przy budowaniu widoku:** Zarówno `DashboardScreen` (`DashboardScheduleColumn`, `DashboardMobileView`), jak i widoki Planu lekcji (`WeeklyGridView`, `AgendaView`, `LessonDetailsModal`) wywoływały `DateTime.now()` wyłącznie wewnątrz `build()` bez żadnego cyklicznego timera ani nasłuchiwania `AppLifecycleState.resumed` / `onShow`. Dopóki żaden inny provider nie wymusił przebudowania drzewa widżetów, pasek postępu i licznik minut stały w miejscu.
2. **Poleganie na statycznym `LessonStatus.inProgress` w Planie lekcji:** W `WeeklyGridView`, `AgendaLessonCard` oraz `LessonDetailsModal` stan aktywnej lekcji był sprawdzany wyłącznie przez `slot.status == LessonStatus.inProgress`. Ponieważ rzeczywiste dane z Firestore/Librusa mają statusy `normal`, `substituted` lub `canceled`, lekcje w Planie lekcji nigdy nie pokazywały stanu „Trwa teraz” ani paska postępu, a warunkowy `Timer.periodic` w `AgendaLessonCard.initState` nigdy się nie uruchamiał.
3. **Brak wizualnego rozróżnienia lekcji odbytych i przyszłych na Pulpicie:** W `DashboardScheduleColumn` wszystkie nieodwołane lekcje spoza aktualnej godziny miały ten sam zielony pasek boczny (`AppColors.secondary`) i plakietkę `PLANOWO`, przez co po zakończeniu lekcji wyglądała ona tak samo jak lekcja zaplanowana na późniejszą godzinę.

## Zakres wprowadzonych zmian

### Task 1: Metody czasowe w `LessonSlot` i reaktywny `currentTimeProvider` (`1671f88`)
- **`lib/domain/models/lesson_slot.dart`:** Dodano metody `startDateTimeOn`, `endDateTimeOn`, `isHappeningAt(now, {lessonDate})`, `isCompletedAt(now, {lessonDate})`, `progressAt(now, {lessonDate})` oraz `remainingMinutesAt(now, {lessonDate})` (zaokrąglające pozostałe sekundy w górę przez `ceil()`, aby w ostatniej minucie lekcji pokazywać `1 min` zamiast `0 min`).
- **`lib/presentation/providers/school_providers.dart`:** Dodano `CurrentTimeNotifier` (`currentTimeProvider`) z `Timer.periodic(const Duration(seconds: 15))` oraz `AppLifecycleListener(onResume: tick, onShow: tick)` (aktywowanymi na rzeczywistym `WidgetsFlutterBinding`) i automatyczną inwalidacją `todayScheduleProvider` / `upcomingExamProvider` przy zmianie dnia kalendarzowego.
- **`lib/data/mock/mock_data.dart`:** Usunięto zahardkodowany `LessonStatus.inProgress` i `progressFraction: 0.65` z czwartkowej lekcji Języka Polskiego, aby również w trybie demonstracyjnym postęp wyliczał się na podstawie rzeczywistego zegara.

### Task 2: Podłączenie odświeżania na żywo na Pulpicie i w Planie lekcji (`208b332`)
- **`DashboardScreen` i `DashboardScheduleColumn`:** Subskrypcja `ref.watch(currentTimeProvider)`. Lekcje w trakcie mają niebieski pasek `AppColors.primary`, plakietkę `W TRAKCIE`, dynamiczny `LinearProgressIndicator` i tekst `Zostało X min`. Lekcje zakończone otrzymują zielony pasek `AppColors.secondary` i zieloną plakietkę `ZREALIZOWANO` z ikoną check, a lekcje nadchodzące mają neutralny pasek `AppColors.outlineVariant` i plakietkę `PLANOWO` (lub pomarańczowy `ZASTĘPSTWO`). Licznik `X / Y zrealizowane` w nagłówku aktualizuje się automatycznie.
- **`DashboardMobileView`:** Subskrypcja `ref.watch(currentTimeProvider)`, licznik `X / Y zrealizowane` w nagłówku karty „Dzisiejszy plan zajęć”, ikona check przy odbytych lekcjach oraz podświetlenie, pozostałe minuty i pasek postępu przy aktualnie trwającej lekcji.
- **`AgendaView`, `AgendaLessonCard`, `WeeklyGridView`, `LessonDetailsModal`:** Przekształcono `AgendaLessonCard` w `ConsumerWidget` subskrybujący `currentTimeProvider`, dodano pasek postępu `LinearProgressIndicator` pod wierszem przedmiotu dla lekcji trwającej na żywo oraz plakietkę `Zrealizowano` i zielony pasek boczny dla odbytych lekcji. W `WeeklyGridView` i `LessonDetailsModal` podłączono `currentTimeProvider`, dynamiczny pasek postępu i odliczanie minut `Trwa teraz • Zostało X min`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Usunięcie `IntrinsicHeight` + `CrossAxisAlignment.baseline` w `AgendaLessonCard`**
- **Found during:** Task 2 (podczas uruchamiania testów widżetowych `AgendaLessonCard` z aktywnym `LinearProgressIndicator`)
- **Issue:** W Material 3 `LinearProgressIndicator` używa wewnątrz `Align` (`RenderPositionedBox`), który w połączeniu z zewnętrznym `IntrinsicHeight` oraz wierszem tytułu z `CrossAxisAlignment.baseline` rzucał asercję `RenderPositionedBox class does not implement "computeDryBaseline"`.
- **Fix:** Zastąpiono `IntrinsicHeight` + 5px `Container` dekoracją `DecoratedBox` z `Border(left: BorderSide(color: stripeColor, width: 5))` (wewnątrz istniejącego kontenera z `clipBehavior: Clip.antiAlias`) oraz wyrównaniem `CrossAxisAlignment.center`.
- **Files modified:** `lib/presentation/screens/schedule/widgets/agenda_lesson_card.dart`
- **Commit:** `208b332`

## Weryfikacja

- `flutter test test/presentation/screens/schedule_live_progress_test.dart` — 7/7 testów jednostkowych i widżetowych PASSED
- `flutter test test/dashboard_screen_test.dart` — 2/2 testów PASSED
- `flutter test test/presentation/screens/schedule/schedule_screen_layout_test.dart` — 2/2 testów PASSED
- `flutter analyze` — `No issues found!`

## Self-Check: PASSED
