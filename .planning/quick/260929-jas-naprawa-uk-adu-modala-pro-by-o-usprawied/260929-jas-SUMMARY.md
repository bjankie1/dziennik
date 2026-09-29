---
phase: quick-260929-jas
plan: 01
subsystem: ui
tags: [flutter, attendance, modal, mobile-ux]
key-files:
  modified:
    - lib/presentation/screens/attendance/widgets/student_justification_modal.dart
    - lib/presentation/screens/attendance/justification_modal.dart
    - lib/presentation/screens/attendance/widgets/parent_approval_modal.dart
    - lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart
    - lib/presentation/screens/attendance/widgets/student_response_modal.dart
    - lib/presentation/screens/attendance/attendance_screen.dart
  created:
    - test/attendance_justification_modal_test.dart
completed: "2026-09-29"
---

# Quick Task 260929-jas: Naprawa układu modala prośby o usprawiedliwienie Summary

**Przebudowano modale usprawiedliwień na ekranie Frekwencji, dodając wyświetlanie na głównym Navigatorze (`useRootNavigator: true`), przewijany środkowy formularz oraz zawsze widoczną, przypiętą na dole stopkę z niebieskim przyciskiem zatwierdzenia.**

## Przyczyna problemu (ze zrzutu ekranu Oskara)
1. **Brak `useRootNavigator: true` w `showModalBottomSheet`:** Modale otwierane wewnątrz `AttendanceScreen` (zagnieżdżonego w `StatefulNavigationShell` wewnątrz `Stack` z `FloatingChatFab("Czat & AI")` i `NavigationBar`) otwierały się wewnątrz podrzędnego navigatora zakładki — przez co były obcinane przez dolny pasek nawigacji i zasłaniane przez pływający przycisk `Czat & AI`.
2. **Brak przewijania i brak przypiętej stopki:** W `StudentJustificationModal`, `JustificationModal` oraz `ParentApprovalModal` cała zawartość znajdowała się w nieprzewijalnym `Column`, przez co na ekranie telefonu przycisk `Wyślij prośbę do rodzica` wychodził poza dolną krawędź ekranu.

## Zakres zmian
- Dodano `useRootNavigator: true` do `showModalBottomSheet` we wszystkich modalach frekwencji (`StudentJustificationModal`, `JustificationModal`, `ParentApprovalModal`, `ParentRejectionModal`, `StudentResponseModal`, `_showRequestedDetailsModal`).
- Podzielono układ każdego modala na 3 części w ramach `ConstrainedBox(maxHeight: height * 0.90)`:
  1. **Stały nagłówek** na górze (uchwyt + ikona i tytuł).
  2. **Przewijana i bardziej kompaktowa sekcja formularza** (`Flexible` + `SingleChildScrollView` ze zmniejszonymi odstępami pionowymi oraz `VisualDensity.compact` na chipach powodów).
  3. **Przypięta na stałe dolna stopka** z głównym przyciskiem zatwierdzenia (`Wyślij prośbę do rodzica` / `Zatwierdź i wyślij usprawiedliwienie` / `Zatwierdź z PIN-em`) oraz `Anuluj`.
- Dodano testy widżetowe w `test/attendance_justification_modal_test.dart` dla małego ekranu mobilnego (`360x640`).
