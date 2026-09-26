---
phase: quick-260926-avg
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/presentation/providers/school_providers.dart
  - lib/presentation/screens/grades/widgets/weighted_average_kpi_card.dart
  - lib/presentation/screens/grades/widgets/average_trajectory_card.dart
  - lib/presentation/screens/grades/widgets/grade_distribution_card.dart
  - lib/presentation/screens/grades/grades_screen.dart
  - lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart
  - lib/data/repositories/firestore_school_repository.dart
autonomous: true
---

# Quick Task 260926-avg: Prawdziwa zmiana średniej po ostatniej ocenie i usunięcie zmyślonej lokaty w klasie

## Cel
Usunięcie zahardkodowanych wartości makietowych (`+0.14`, `Top 5% w klasie ... (1. lokata na 28 uczniów)`, `Pozycja: 2 / 28`, `Średnia klasy (4.18)`) z widoku Ocen oraz Pulpitu i zastąpienie ich rzeczywistym wyliczeniem wpływu ostatniej oceny na średnią ważoną (`lastGradeDelta`) oraz rzeczywistą trajektorią ocen z Librusa.

## Zadania
1. **Wyliczenie `lastGradeDelta`, `lastGrade` oraz `trajectory` w `GradesDistributionStats` (`school_providers.dart`)**:
   - Sortowanie ocen liczonych do średniej chronologicznie (wg daty i kolejności w dzienniku).
   - Wyliczenie różnicy między aktualną średnią ważoną a średnią ważoną przed wystawieniem ostatniej oceny (`lastGradeDelta`).
   - Usunięcie zahardkodowanego fallbacku `overallAverage: 4.82` podczas ładowania.
2. **Aktualizacja kart KPI i wykresu trajektorii (`weighted_average_kpi_card.dart`, `grades_screen.dart`, `dashboard_metrics_column.dart`, `average_trajectory_card.dart`)**:
   - Dynamiczna pigułka zmiany średniej (`+X.XX` na zielono lub `-X.XX` na czerwono z odpowiednią strzałką trendu).
   - Zastąpienie zmyślonej lokaty w klasie (niedostępnej w Librusie ze względów RODO) informacją o ostatniej ocenie (`Ostatnia ocena: X (waga Y) • Przedmiot`).
   - Wykres trajektorii oparty na rzeczywistych ocenach z semestru zamiast sztywnych punktów z makiety.
