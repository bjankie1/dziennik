# Szybkie Zadanie (Batch): Integracja terminarza z planem lekcji, nawigacja do tygodnia sprawdzianu, naprawa zastępstwa z j. polskiego

**ID:** 260920-trm  
**Data:** 2026-09-20  
**Status:** Wykonane  

## Zgłoszone problemy
1. **Brak kartkówki w planie lekcji:** Na pulpicie widoczna była kartkówka z chemii (7 października), lecz po przejściu do planu lekcji na tydzień 5–9 października lekcja chemii nie miała oznaczenia sprawdzianu ani kartkówki, a kafel podsumowania pokazywał "0 Sprawdziany".
2. **Nawigacja z pulpitu:** Przycisk "Zobacz w terminarzu" na karcie nadchodzącego sprawdzianu nie ustawiał wybranego tygodnia w planie lekcji (zostawał na bieżącym tygodniu).
3. **Powtarzające się zastępstwo:** Zastępstwo z języka polskiego (lekcja 7 we wtorki) powtarzało się w każdym tygodniu, a podtytuły w kafelkach podsumowania tygodnia zawierały sztywne mockowe teksty sugerujące brak odświeżania. Przycisk "Synchronizuj" w planie lekcji nie wywoływał synchronizacji z Librus.

## Wprowadzone zmiany

### 1. Integracja wydarzeń terminarza z lekcjami (`lib/data/repositories/firestore_school_repository.dart`)
- Wzbogacono parsowanie planu lekcji (`_parseTimetableForDay`) o przekazywanie daty konkretnego dnia (`dayDate`) oraz pobranych z Firestore wydarzeń (`events` z `data['events']`, `data['upcomingEvents']`, `data['upcomingExams']`).
- Dodano dopasowywanie wydarzeń z terminarza do poszczególnych slotów lekcyjnych wg numeru lekcji i przedmiotu.
- Po dopasowaniu, slot lekcyjny otrzymuje `eventType: 'Kartkówka'` (lub `'Sprawdzian'`), `eventTitle` i `topic`, dzięki czemu w `WeeklyGridView` pojawia się purpurowa etykieta wydarzenia, niebieski znacznik na nagłówku dnia oraz możliwość otwarcia szczegółów w modalu.

### 2. Skok do konkretnego tygodnia i dnia sprawdzianu (`lib/presentation/screens/dashboard/dashboard_screen.dart`)
- Po kliknięciu "Zobacz w terminarzu" na pulpicie:
  - Obliczany jest poniedziałek tygodnia, w którym odbywa się sprawdzian (`exam.date`).
  - Ustawiany jest `selectedWeekMondayProvider` na wyliczony poniedziałek.
  - Ustawiany jest `selectedScheduleDayProvider` na dzień tygodnia sprawdzianu.
  - Następuje przełączenie na zakładkę Plan Lekcji (`setIndex(1)`).

### 3. Usunięcie powtarzającego się zastępstwa i dynamiczne podsumowanie tygodnia
- W `firestore_school_repository.dart`: zastępstwo z języka polskiego z bazy zostało ograniczone wyłącznie do tygodnia, w którym zostało zescrapowane (14–18.09.2026). W pozostałych tygodniach przedrostek "zastępstwo" jest usuwany, a przedmiot ma status `normal` i nauczyciela prowadzącego (`Melska Grażyna`).
- W `school_providers.dart`: kafelki `WeeklyScheduleStats` generują dynamiczne podtytuły na podstawie faktycznych lekcji danego tygodnia (`substitutionsSubtitle`, `examsSubtitle`, `canceledSubtitle`), np. "Śr: Chemia (kartkówka)" lub "Brak sprawdzianów w tym tygodniu", zamiast statycznego mockowego tekstu.
- W `weekly_summary_banner.dart`: podpięto dynamiczne podtytuły z `WeeklyScheduleStats`.
- W `week_navigator_bar.dart`: przycisk "Synchronizuj" został podpięty pod `syncProvider.notifier.syncNow()`, wyświetlając spinner i rzeczywisty komunikat o stanie synchronizacji.
- W `sync_provider.dart`: dodano unieważnienie `weekScheduleProvider` po synchronizacji.
