# Phase 8: Pełny design ekranu głównego w wersji web - UI Specification

**Status:** Final
**Design Source:** `docs/start_page_web_v1/` (`screen.png`, `code.html`, `DESIGN.md`)

---

## 1. Design Tokens & Visual Hierarchy

### Typography (Plus Jakarta Sans)
- **Headline-LG:** 28px / 34px line-height, bold (700) — Welcome header ("Dzień dobry, Oskar! 👋")
- **Headline-MD:** 20px / 26px line-height, semi-bold (600) — Section card headers, primary metric values
- **Headline-SM:** 16px / 22px line-height, semi-bold (600) — Card titles, lesson subject names
- **Body-LG:** 15px / 22px line-height, regular (400) — Welcome subtitle date/time line
- **Body-MD:** 13px / 18px line-height, regular (400) — Message snippet, subtitle details
- **Body-SM:** 11px / 15px line-height, regular (400) — Timestamps, teacher names, room labels
- **Label-LG:** 13px / 16px line-height, semi-bold (600) — Sidebar nav labels, button labels
- **Label-MD:** 11px / 14px line-height, semi-bold (600) — Pill buttons, filters, lesson times
- **Label-SM:** 10px / 12px line-height, bold (700), tracking +0.04em — All-caps category badges (ODWOŁANE, W TRAKCIE, ZASTĘPSTWO, SPRAWDZIAN)

### Color Tokens
- **Background / Canvas:** `#F8F9FF` (AppColors.surface)
- **Surface Elevation (Cards):** `#FFFFFF` (AppColors.surfaceContainerLowest) with 1px border `#E2E8F0` or subtle shadow
- **Surface Low (Pills, inputs):** `#EFF4FF` (AppColors.surfaceContainerLow)
- **Primary (Accent & Active):** `#3525CD` (AppColors.primary) / `#4F46E5` (AppColors.primaryContainer)
- **Secondary (Attendance & Success):** `#006C4A` (AppColors.secondary) / `#82F5C1` (AppColors.secondaryContainer)
- **Tertiary (Substitutions & Warnings):** `#703A00` (AppColors.tertiary) / `#FFDCC3` (AppColors.tertiaryFixed)
- **Error (Cancellations & Severe):** `#BA1A1A` (AppColors.error) / `#FFDAD6` (AppColors.errorContainer)

---

## 2. Layout & Responsive Breakpoints

- **Desktop (>= 1024px):**
  - Left persistent **AppSidebar** (width 256px / w-64).
  - Top persistent **AppDesktopHeader** (height 64px / h-16) with search bar, notifications, and student profile.
  - Body container with 3-column Bento Grid (`lg:grid-cols-12`):
    - Column 1 (`col-span-4`): Harmonogram lekcji na dziś + nadchodzący sprawdzian.
    - Column 2 (`col-span-5`): Wiadomości i komunikaty ze strumieniem wątków + komunikat szkoły.
    - Column 3 (`col-span-3`): Ostatnie oceny + pasek frekwencji z celem 90% + mozaika szybkich skrótów.
- **Mobile (< 1024px):**
  - Top mobile AppHeader.
  - Single-column scrollable dashboard.
  - Bottom persistent NavigationBar.

---

## 3. UI Component Details

### A. AppSidebar (Common Navigation Shell)
- Logo EduSync (32px icon + title text "EduSync" in primary indigo + "LO nr X im. Stefanii Sempołowskiej").
- Semester indicator pill: "Semestr 1 / 2024-2025" in `surfaceContainerLow` container.
- Nav Items list:
  1. **Pulpit** (`Icons.grid_view`)
  2. **Plan Lekcji** (`Icons.schedule`)
  3. **Oceny i Średnie** (`Icons.verified`)
  4. **Frekwencja** (`Icons.fact_check`) with red badge if unexcused absences > 0
  5. **Wiadomości i Ogłoszenia** (`Icons.chat`) with primary badge if unread messages > 0
- Active item style: `bg-primary-container` (`#4F46E5`), pure white icon and text, 12px border radius.
- Bottom status widget: "Rada Rodziców & Dziennik" / "Aktualizacja: Dzisiaj, HH:MM".

### B. AppDesktopHeader
- Global search field with `Icons.search`, placeholder "Szukaj w ocenach, planie, wiadomościach...", background `surfaceContainerLow`, `rounded-xl`.
- Notification button with counter badge.
- Student profile pill: Avatar circle, "Oskar Jankiewicz", "Klasa 4 k Lic", dropdown icon -> opens profile/logout sheet.

### C. Dashboard Top Banner
- Greeting: "Dzień dobry, Oskar! 👋" + "Tydzień B • Semestr 1" + "Stan normalny".
- Summary row: Date string, start time, end time, effective lesson count.
- 4 Mini-metric cards:
  1. Średnia ważona (`4.82` / `Top 5%`)
  2. Frekwencja (`98.6%` / `Cel: >90%`)
  3. Wiadomości (`3 nieprzeczytane`)
  4. Szczęśliwy numerek / Sprawdziany (`14` / `1 za 3 dni`)

### D. Lesson Timeline (Harmonogram dnia)
- Header: "Harmonogram na dziś" + "X / Y zrealizowane" pill.
- Lesson item structure:
  - 4px vertical colored stripe on the left edge.
  - Time interval (e.g. 08:50 - 09:35).
  - Status pill: ODWOŁANE (error), W TRAKCIE (primary), ZASTĘPSTWO (tertiary), PLANOWO (neutral).
  - Lesson number + Subject title + Room.
  - For "W trakcie": pulsing dot indicator, linear progress bar (% elapsed), remaining minutes label ("Zostało 15 min").
- Bottom button: "Pełny plan lekcji na cały tydzień →".

### E. Messages & Bulletins (Wiadomości i Komunikaty)
- Header: "Wiadomości i Komunikaty" + "Otwórz skrzynkę →".
- Filter tab pills: "Nieprzeczytane (X)", "Wszystkie", "Ogłoszenia (Y)".
- Message cards: unread dot, sender name, urgency badges (PILNE, DYREKCJA), subject, text preview, PDF attachment chip, "Odpowiedz" button, "Oznacz jako przeczytane" button.
- Bulletin highlight card: "14 Listopada: Dzień Wolny - Konferencja metodyczna...".

### F. Grades, Attendance & Quick Shortcuts
- Recent grades card: "+0.12 do średniej" pill, grade cards with weight and subject, "Zobacz wszystkie oceny →".
- Attendance card: percentage, 2-color attendance progress bar (cel roczny 90%), warning pill for unexcused absences, "Szybkie usprawiedliwienie (PIN)" primary button.
- Quick action mosaic: "Zadania domowe", "Kontakt z wychowawcą", "Zgłoś nieobecność".
