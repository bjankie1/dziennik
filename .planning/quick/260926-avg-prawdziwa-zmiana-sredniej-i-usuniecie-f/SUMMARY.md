# Quick Task 260926-avg Summary: Prawdziwa zmiana średniej i usunięcie zmyślonej lokaty w klasie

## Co zostało naprawione
1. **Prawdziwa zmiana średniej po ostatniej ocenie (`lastGradeDelta`)**:
   - W `gradesDistributionStatsProvider` (`lib/presentation/providers/school_providers.dart`) oceny liczone do średniej są sortowane chronologicznie i wyliczana jest rzeczywista różnica między średnią ważoną z uwzględnieniem ostatniej oceny a średnią ważoną bez niej (`avg - prevAvg`).
   - Przy ostatniej ocenie `1` (obniżającej średnią do `2.78`) wskaźnik obok średniej pokazuje teraz rzeczywisty spadek (np. czerwona pigułka ze strzałką w dół `Icons.trending_down_rounded` i ujemną wartością), zamiast zahardkodowanego z makiety zielonego `+0.14`.
2. **Usunięcie nieprawdziwego rankingu w klasie (`Top 5%`, `1. lokata na 28 uczniów`, `Pozycja: 2 / 28`)**:
   - Librus Synergia nie udostępnia lokaty ucznia w klasie ani liczby uczniów ani średniej klasy (ograniczenia prywatności / RODO).
   - Usunięto zahardkodowane `classRank: 1, totalStudentsInClass: 28` z `FirestoreSchoolRepository` oraz napisy `Top 5% w klasie ... (1. lokata na 28 uczniów)` z `WeightedAverageKpiCard`, `GradesScreen` (widok mobilny) i `DashboardMetricsColumn` (Pulpit).
   - W stopce karty średniej ważonej wyświetlana jest teraz prawdziwa informacja o ostatniej ocenie wpływającej na średnią (`Ostatnia ocena: [ocena] (waga [X]) • [Przedmiot]`).
3. **Rzeczywista trajektoria średniej w semestrze (`AverageTrajectoryCard`)**:
   - Zastąpiono sztywne punkty makiety (`4.60 -> 4.78`) oraz zmyśloną średnią klasy (`4.18`) rzeczywistym przebiegiem skumulowanej średniej ważonej ucznia po kolejnych ocenach oraz progiem wyróżnienia (`4.75`).
