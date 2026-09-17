---
phase: 08-pe-ny-design-ekranu-g-wnego-w-wersji-web
plan: 01
status: complete
requirements_completed: [REQ-DASH-02]
---

# Phase 8 Plan 01: Global Responsive Navigation Shell & Header - Summary

**Execution Date:** 2026-09-16
**Status:** Success
**Requirements:** REQ-DASH-02

---

## 1. What was built

1. **`lib/presentation/widgets/app_sidebar.dart`:**
   - Dedykowany, stylowy lewy pasek boczny nawigacji desktopowej (szerokość 256px, kolor tła `AppColors.surfaceContainerLowest` `#FFFFFF`).
   - Nagłówek marki z logo EduSync (34px), nazwą aplikacji w kolorze primary indygo oraz nazwą szkoły ucznia ("LO nr X im. Stefanii Sempołowskiej").
   - Selektor semestru w zaokrąglonym kontenerze ("Semestr 1 / 2024-2025").
   - 5 zakładek nawigacji: Pulpit, Plan Lekcji, Oceny i Średnie, Frekwencja, Wiadomości i Ogłoszenia.
   - Wyróżnienie aktywnego elementu: zaokrąglenie 12px, tło `AppColors.primaryContainer` (`#4F46E5`), biały tekst i ikona.
   - Dynamiczne badge liczników: nieusprawiedliwione godziny na zakładce Frekwencji oraz nieprzeczytane wiadomości na zakładce Wiadomości.
   - Dolny widżet stanu synchronizacji z Librusem ("Rada Rodziców & Dziennik", "Aktualizacja: Dzisiaj, HH:MM").

2. **`lib/presentation/widgets/app_desktop_header.dart`:**
   - Dedykowany nagłówek desktopowy (wysokość 64px, tło `surfaceContainerLowest` z rozmyciem i obramowaniem).
   - Globalne pole wyszukiwania z placeholderem "Szukaj w ocenach, planie, wiadomościach...", ikoną lupy i zaokrągleniem 12px.
   - Przycisk dzwonka powiadomień z dynamicznym badge liczby nieprzeczytanych wiadomości.
   - Pigułka profilu ucznia z awatarem, imieniem ("Oskar Jankiewicz"), klasą ("Klasa 4 k Lic") oraz menu rozwijanym.

3. **`lib/presentation/screens/main_navigation_screen.dart`:**
   - Refaktoryzacja na responsywny `LayoutBuilder`.
   - Na ekranach desktopowych (szerokość >= 1024px):
     - Zastosowano wspólny Desktop Shell: stały lewy `AppSidebar`, górny `AppDesktopHeader` oraz centralny obszar `IndexedStack`.
     - Nawigacja boczna jest teraz **wspólna dla wszystkich zakładek** (Pulpit, Plan, Oceny, Frekwencja, Wiadomości).
     - Dolny `NavigationBar` jest ukryty na desktopie.
   - Na ekranach mobilnych (< 1024px):
     - Zachowano dotychczasowy układ mobilny z `AppHeader`, `IndexedStack` i dolnym `NavigationBar`.

4. **`test/navigation_shell_test.dart`:**
   - Test widżetowy weryfikujący obecność `AppSidebar` i `AppDesktopHeader` na desktopie oraz dolnego paska nawigacji na urządzeniach mobilnych.

---

## 2. Verification

- `flutter analyze` — No issues found!
- `flutter build web --release` — Zbudowano pomyślnie `build/web` (exit code 0).
