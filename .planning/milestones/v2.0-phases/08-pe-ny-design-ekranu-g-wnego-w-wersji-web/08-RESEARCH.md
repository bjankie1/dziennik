# Phase 8: Pełny design ekranu głównego w wersji web - Research

**Date:** 2026-09-16
**Status:** Complete
**Confidence:** HIGH

---

## User Constraints

### Locked Decisions (from CONTEXT.md)
- **D-01 (Crucial):** Na ekranach desktopowych (szerokość >= 1024px) wdrażamy dedykowany lewy panel boczny (Sidebar, szerokość 256px / w-64) oraz górny nagłówek (Header, wysokość 64px / h-16) jako **wspólną powłokę nawigacyjną (Shell) dla wszystkich widoków aplikacji** (Pulpit, Plan Lekcji, Oceny i Średnie, Frekwencja, Wiadomości i Ogłoszenia), a nie tylko dla strony głównej.
- **D-02:** Główna przestrzeń pulpitu na desktopie wykorzystuje 3-kolumnowy Bento Grid (\`lg:grid-cols-12\` z makiety Stitch):
  - Kolumna lewa (\`col-span-4\`): Harmonogram lekcji na dziś + nadchodzący sprawdzian.
  - Kolumna środkowa (\`col-span-5\`): Wiadomości i komunikaty z pigułkami filtrów + szkolny komunikat specjalny.
  - Kolumna prawa (\`col-span-3\`): Ostatnie oceny + frekwencja z miernikiem i celem rocznym + szybkie akcje.
- **D-03:** Na tabletach (768px – 1023px) układ adaptuje się płynnie do 2 kolumn, a na urządzeniach mobilnych (< 768px) zachowuje ergonomiczny układ jednokolumnowy z dolnym paskiem nawigacji (Bottom Navigation Bar) i nagłówkiem mobilnym. Na desktopie dolny pasek nawigacji jest ukryty, a nawigację w 100% przejmuje Sidebar.
- **D-04:** Pasek wyszukiwania w nagłówku ("Szukaj w ocenach, planie, wiadomościach...") odzwierciedla styl z makiety Stitch (\`bg-surface-container-low\`, zaokrąglenie \`rounded-xl\`, ikona lupy) i umożliwia dynamiczne filtrowanie oraz szybkie przejście (Command Palette / Search Modal) do pasujących lekcji, ocen i wiadomości.
- **D-05:** Harmonogram dnia prezentuje lekcje z pionowym paskiem kategorii kolorystycznej (zielony dla planowych, pomarańczowy/tertiary dla zastępstw, czerwony dla odwołanych/sprawdzianów, indygo dla bieżącej).
- **D-06:** System w czasie rzeczywistym porównuje aktualną godzinę systemową z przedziałami lekcji:
  - Dla aktualnie trwającej lekcji wyświetla pulsujący badge \`W trakcie\` (\`animate-ping\`), oblicza i animuje pasek postępu (np. 65%) oraz czas do zakończenia (\`Zostało X min\`).
  - Pokazuje temat lekcji oraz nauczyciela i numer sali (z uwzględnieniem ewentualnej zmiany sali / zastępstwa).
- **D-07:** Sekcja wiadomości zawiera przełącznik filtrów (pigułki \`Nieprzeczytane\`, \`Wszystkie\`, \`Ogłoszenia\`), dynamicznie filtrujący listę.
- **D-08:** Karty wiadomości posiadają wskaźnik nieprzeczytania (kropka primary), etykiety pilności (\`PILNE\`, \`DYREKCJA\`), nadawcę, datę/godzinę, podgląd treści oraz przycisk szybkiej akcji \`Odpowiedz\` (otwierający formularz odpowiedzi w wątku) oraz ikonę \`Oznacz jako przeczytane\`.
- **D-09:** Pod listą wiadomości wyświetlany jest szkolny baner informacyjny (np. konferencja/dzień wolny) z przyciskiem akcji.
- **D-10:** Karta ocen prezentuje wskaźnik trendu średniej ważonej (\`+0.12 do średniej\`), listę ostatnich ocen z kolorowymi kafelkami ocen (np. \`5\`, \`4+\`), wagami i przedmiotami oraz linkiem \`Zobacz wszystkie oceny\`.
- **D-11:** Karta frekwencji zawiera dwukolorowy poziomy pasek postępu z progiem minimalnym 50% i celem rocznym 90%, ostrzeżenie o nieusprawiedliwionych godzinach oraz przycisk \`Szybkie usprawiedliwienie (PIN)\`.
- **D-12:** Podpięcie kafelków szybkich akcji:
  - Przycisk \`Szybkie usprawiedliwienie (PIN)\` oraz kafelek \`Zgłoś nieobecność\` otwierają modal e-Usprawiedliwień z obsługą PIN rodzica i wysyłką do Librusa.
  - Kafelek \`Czat / Kontakt z wychowawcą\` otwiera formularz nowej wiadomości z automatycznie uzupełnionym wychowawcą.
  - Kafelek \`Zadania domowe\` oraz \`Pełny plan lekcji na cały tydzień\` kierują bezpośrednio do widoku terminarza / planu lekcji.

---

## Standard Stack

[VERIFIED: pubspec.yaml:30-46]
- **Flutter Framework:** Flutter 3.x / Dart 3.x z Material 3 włączonym (\`useMaterial3: true\`).
- **State Management:** \`flutter_riverpod: ^3.3.2\`. Wszystkie dane ekranu czerpią z istniejących providerów:
  - \`currentNavIndexProvider\` — indeks aktywnego widoku nawigacji.
  - \`studentProfileProvider\` — dane ucznia (Oskar Jankiewicz, klasa, szkoła, frekwencja %, średnia ważona, szczęśliwy numerek).
  - \`todayScheduleProvider\` — harmonogram lekcji na dziś (\`LessonSlot\`, godziny, sale, statusy).
  - \`recentGradesProvider\` — ostatnio dodane oceny (\`Grade\`).
  - \`attendanceProvider\` — wpisy obecności/nieobecności (\`AttendanceRecord\`).
  - \`messagesProvider\` — wątki wiadomości (\`MessageThread\`).
  - \`syncProvider\` — stan synchronizacji z Librusem.
- **Typography & Theme:** \`google_fonts: ^8.2.1\` z rodziną fontów **Plus Jakarta Sans** zdefiniowaną w \`AppTheme.lightTheme\`.
- **Color Palette & Tokens:** Zdefiniowane w \`AppColors\` (\`lib/core/theme/app_colors.dart\`), zgodne w 100% z \`docs/start_page_web_v1/DESIGN.md\`.

---

## Architecture Patterns

### 1. Global Responsive Navigation Shell (\`MainNavigationScreen\`)
Aby zrealizować kluczowe wymaganie użytkownika o **wspólnym pasku bocznym dla wszystkich widoków**:
- Zamiast zaszywać pasek boczny tylko w \`DashboardScreen\`, modyfikujemy \`lib/presentation/screens/main_navigation_screen.dart\`.
- Wykorzystujemy \`LayoutBuilder\` do wykrywania szerokości ekranu (\`constraints.maxWidth >= 1024\` dla Desktopu).
- **Na Desktopie (>= 1024px):**
  - Ukrywamy dolny pasek nawigacji (\`bottomNavigationBar: null\`).
  - Układ aplikacji to \`Row\`:
    - Po lewej stronie: Nowy komponent \`AppSidebar\` (stała szerokość 256px, kolor tła \`surfaceContainerLowest\`, cień, nagłówek szkoły, selektor semestru, lista linków nawigacyjnych z wyróżnieniem aktywnego widoku oraz badge'ami nieprzeczytanych wiadomości i nieusprawiedliwionych nieobecności, widget stanu synchronizacji na dole).
    - Po prawej stronie: \`Expanded\` zawierający \`Column\`:
      - Górny pasek \`AppDesktopHeader\` (wysokość 64px, search bar, powiadomienia z badge, chip profilu ucznia).
      - Główny obszar roboczy: \`Expanded(child: IndexedStack(index: currentIndex, children: screens))\`.
  - W ten sposób **wszystkie ekrany** (Pulpit, Plan Lekcji, Oceny, Frekwencja, Wiadomości) są automatycznie osadzone w nowym, eleganckim layoucie webowym z lewym paskiem nawigacyjnym!
- **Na Mobile (< 1024px / < 768px):**
  - Wyświetlamy dotychczasowy układ: mobilny \`AppHeader\`, \`IndexedStack\` oraz dolny pasek \`NavigationBar\`.

### 2. Desktop Bento Grid dla Pulpitu (\`DashboardScreen\`)
Gdy szerokość ekranu >= 1024px, \`DashboardScreen\` renderuje pełny widok Bento Grid z \`docs/start_page_web_v1/code.html\`:
1. **Banner powitalny (Top Welcome & Metric Banner):**
   - Powitanie ucznia z imieniem, pigułki tygodnia (np. "Tydzień B • Semestr 1"), wskaźnik stanu ("Stan normalny").
   - Linia podsumowania dnia: sformatowana data, godzina pierwszej i ostatniej lekcji, liczba lekcji efektywnych, informacja o odwołaniach/zastępstwach.
   - 4 kafelki mini-metryk: Średnia ważona, Frekwencja z celem, Wiadomości nieprzeczytane, Szczęśliwy numerek / Sprawdziany.
2. **3-Kolumnowy Bento Grid:**
   - **Kolumna 1 (Lewa, flex ~4):**
     - Karta \`Harmonogram na dziś\` z licznikiem lekcji zrealizowanych.
     - Elementy lekcji z 4-pikselowym pionowym paskiem kategorii (zielony, czerwony, pomarańczowy, indygo).
     - Obsługa lekcji w toku (\`W trakcie\`) z pulsującym wskaźnikiem, paskiem postępu i czasem do końca.
     - Przycisk \`Pełny plan lekcji na cały tydzień →\` (przełączający \`currentNavIndexProvider\` na 1 - Plan).
     - Karta \`Nadchodzący sprawdzian\` z odliczaniem czasu.
   - **Kolumna 2 (Środkowa, flex ~5):**
     - Karta \`Wiadomości i Komunikaty\` z linkiem \`Otwórz skrzynkę →\` (przełącza \`currentNavIndexProvider\` na 4 - Wiadomości).
     - Pigułki filtrów: \`Nieprzeczytane (X)\`, \`Wszystkie\`, \`Ogłoszenia (Y)\`.
     - Lista wiadomości z nadawcą, badge'em \`PILNE\` / \`DYREKCJA\`, tematem, fragmentem treści, załącznikiem i przyciskiem \`Odpowiedz\` (otwiera modal \`ComposeMessageModal\` w trybie odpowiedzi).
     - Szkolny baner komunikatów (np. informacja o konferencji/dniu wolnym).
   - **Kolumna 3 (Prawa, flex ~3):**
     - Karta \`Ostatnie oceny\` z trendem średniej, kafelkami ocen z wagami i linkiem \`Zobacz wszystkie oceny\` (przełącza nav na 2 - Oceny).
     - Karta \`Frekwencja\` z podwójnym paskiem postępu (procent frekwencji vs cel 90%), ostrzeżeniem o godzinach do usprawiedliwienia i przyciskiem \`Szybkie usprawiedliwienie (PIN)\` (wywołuje \`QuickExcuseDialog\`).
     - Kafelki szybkich akcji: \`Zadania domowe\`, \`Kontakt z wychowawcą\` (otwiera \`ComposeMessageModal\`), \`Zgłoś nieobecność\` (otwiera \`QuickExcuseDialog\`).

---

## Don't Hand-Roll

- **Nie twórz osobnego routera/nawigatora:** Wykorzystaj istniejący \`currentNavIndexProvider\` i \`IndexedStack\` w \`MainNavigationScreen\`. Zapewnia to zachowanie stanu każdego ekranu bez niepotrzebnych re-renderów.
- **Nie twórz od nowa formularza wiadomości:** Używaj istniejącego \`showComposeMessageModal(context, recipient: teacher)\`.
- **Nie twórz od nowa logiki e-Usprawiedliwień:** Używaj istniejącego \`showDialog(context: context, builder: (_) => const QuickExcuseDialog())\`.
- **Nie twórz własnych fontów/kolorów:** Korzystaj bezpośrednio z \`AppColors\` i \`Theme.of(context).textTheme\`.

---

## Common Pitfalls

1. **Przepełnienie szerokości (Overflow) w kolumnach:**
   - Na węższych ekranach desktopowych (np. 1024-1280px) stałe szerokości kolumn mogą powodować błędy RenderFlex overflow.
   - *Rozwiązanie:* Stosowanie \`Flexible\` / \`Expanded\` z wagami flex (np. 4:5:3) wewnątrz \`Row\`, w połączeniu z \`SingleChildScrollView\` pionowym dla całej strony głównej.
2. **Kalkulacja trwającej lekcji:**
   - Godziny lekcji mogą być w formatach "08:00 - 08:45" lub polach \`startTime\`, \`endTime\`. Jeśli czas jest poza godzinami zajęć, żadna lekcja nie powinna mieć statusu "W trakcie".
   - *Rozwiązanie:* Bezpieczny parser godzin (np. \`TimeOfDay\` lub \`DateTime\`), obliczający postęp minionego czasu tylko gdy \`now >= start && now <= end\`.
3. **Synchronizacja liczników badge:**
   - Liczba nieprzeczytanych wiadomości i nieusprawiedliwionych nieobecności musi być identyczna w \`AppSidebar\`, \`AppDesktopHeader\` oraz w mobilnym \`AppHeader\` i \`NavigationBar\`.
   - *Rozwiązanie:* Wspólne pobieranie z providerów (\`unreadMessagesCountProvider\`, \`attendanceProvider\`).

---

## Code Examples

### 1. Global Shell w \`MainNavigationScreen\`
\`\`\`dart
return LayoutBuilder(
  builder: (context, constraints) {
    final isDesktop = constraints.maxWidth >= 1024;
    
    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Row(
          children: [
            AppSidebar(
              currentIndex: currentIndex,
              onIndexSelected: (idx) => ref.read(currentNavIndexProvider.notifier).setIndex(idx),
              unexcusedCount: unexcusedCount,
              unreadCount: messageBadgeCount,
              student: student,
            ),
            Expanded(
              child: Column(
                children: [
                  AppDesktopHeader(
                    student: student,
                    unreadCount: messageBadgeCount,
                    onNotificationsTap: () => ref.read(currentNavIndexProvider.notifier).setIndex(4),
                    onProfileTap: () => _showProfileSheet(context, ref),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: currentIndex,
                      children: screens,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Mobile Layout (< 1024px)
    return Scaffold(
      appBar: AppHeader(...),
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(...),
    );
  },
);
\`\`\`

---

## Validation Architecture

Nyquist validation requirements for Phase 8:
1. **Automated Verification:**
   - \`flutter analyze\` — brak jakichkolwiek błędów i warningów lintera.
   - \`flutter test\` — pomyślne przejście testów jednostkowych i widżetowych.
   - Nowy test widżetowy weryfikujący:
     - Wyświetlanie \`AppSidebar\` i \`AppDesktopHeader\` przy szerokości >= 1024px.
     - Wyświetlanie \`NavigationBar\` i brak paska bocznego przy szerokości mobilnej (< 1024px).
     - Poprawne przełączanie zakładek za pomocą paska bocznego na desktopie.
2. **Manual Verification:**
   - Uruchomienie aplikacji w przeglądarce (Chrome) w widoku pełnoekranowym (desktop >= 1200px) oraz zweryfikowanie zgodności z makietą \`docs/start_page_web_v1/screen.png\`.
   - Zweryfikowanie działania zakładek nawigacji bocznej z widoku Ocen, Planu, Frekwencji i Wiadomości.
   - Sprawdzenie działania skrótów: otwarcie e-Usprawiedliwień (PIN) i kontaktu z wychowawcą.

