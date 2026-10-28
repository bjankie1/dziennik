---
phase: 261028-a6e
plan: 01
subsystem: ui
tags: [flutter, attendance, chat-ai, mobile-ux]
status: complete
key_files:
  modified:
    - lib/presentation/screens/main_navigation_screen.dart
    - lib/presentation/widgets/app_header.dart
    - lib/presentation/widgets/chat/floating_chat_fab.dart
    - lib/presentation/screens/attendance/widgets/floating_justification_dock.dart
    - test/attendance_pending_requests_test.dart
completed: "2026-10-28T07:22:46+01:00"
---

# Quick Task 261028-a6e Summary: Przeniesienie przycisku Czat & AI do górnego paska na mobile (AppHeader) oraz układ Wrap dla szybkich powodów usprawiedliwień w FloatingJustificationDock

## Problem
Na ekranach mobilnych (`<1024px`) pływający przycisk `FloatingChatFab` („Czat & AI ✨”) był zakotwiczony na sztywno w prawym dolnym rogu (`bottom: 84, right: 16` na zakładce Frekwencja). Gdy użytkownik zaznaczył lekcje do usprawiedliwienia, dolny panel `FloatingJustificationDock` wysuwał się na wysokość ok. `210px`, przez co przycisk „Czat & AI ✨” zasłaniał opcje szybkiego wyboru powodu nieobecności (w szczególności „Zawody sportowe” oraz część „Sprawy rodzinne”). Ponadto opcje powodów w `FloatingJustificationDock` znajdowały się w poziomym `SingleChildScrollView`, przez co ostatnia opcja wystawała poza krawędź ekranu.

## Rozwiązanie
1. **Przeniesienie „Czat & AI ✨” do górnego paska (`AppHeader`) na mobile i usunięcie pływającego FAB-a (`<1024px`):**
   - W `MainNavigationScreen` całkowicie usunięto pływający przycisk `FloatingChatFab(isDesktop: false)` w układzie mobilnym, dzięki czemu żaden pływający element nie przysłania dolnych paneli ani treści na żadnej zakładce. Na widoku desktopowym (`>=1024px`) przycisk działa bez zmian.
   - W mobilnym nagłówku `AppHeader` zastąpiono ikonę zwykłego czatu wyróżnioną pigułką `✨ AI` z gradientem i obsługą plakietki nieprzeczytanych wiadomości (`chatUnreadCount`), która otwiera dwutrybowy arkusz `FloatingChatPanel(isInsideBottomSheet: true)` (`useRootNavigator: true`, dostęp do Czatu Rodzinnego i Asystenta AI).
2. **Zawijana siatka (`Wrap`) dla szybkich powodów nieobecności w `FloatingJustificationDock`:**
   - Zastąpiono `SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(...))` komponentem `Wrap(spacing: 8, runSpacing: 8)`, dzięki czemu wszystkie 4 szybkie powody (`Choroba`, `Wizyta lekarska`, `Sprawy rodzinne`, `Zawody sportowe`) są od razu widoczne bez przewijania w poziomie.
   - Zabezpieczono tekst przycisku wysyłki i stopki w `FloatingJustificationDock` za pomocą `Flexible` + `TextOverflow.ellipsis` przed przepełnieniem na węższych ekranach.

## Commits
- `af75214`: `fix(ui): move mobile Chat & AI action to AppHeader and wrap quick excuse reasons`
