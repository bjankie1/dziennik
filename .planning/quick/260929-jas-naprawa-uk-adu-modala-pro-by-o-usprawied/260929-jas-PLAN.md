---
phase: quick-260929-jas
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/presentation/screens/attendance/widgets/student_justification_modal.dart
  - lib/presentation/screens/attendance/justification_modal.dart
  - lib/presentation/screens/attendance/widgets/parent_approval_modal.dart
  - lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart
  - lib/presentation/screens/attendance/widgets/student_response_modal.dart
  - test/attendance_justification_flow_test.dart
autonomous: true
requirements: []
must_haves:
  truths:
    - "Modale usprawiedliwień (ucznia i rodzica) otwierają się na root Navigatorze (`useRootNavigator: true`), powyżej dolnego paska nawigacji oraz pływającego przycisku Czat & AI"
    - "Główny przycisk zatwierdzenia (niebieski przycisk 'Wyślij prośbę do rodzica', 'Zatwierdź i wyślij usprawiedliwienie', itp.) oraz 'Anuluj' są zawsze przypięte i widoczne na dole modala niezależnie od wysokości ekranu telefonu"
    - "Środkowa część formularza (wybór dat, szybkie powody, pole tekstowe, info box) jest przewijana (`Flexible` + `SingleChildScrollView`) i bardziej kompaktowa w pionie"
  artifacts:
    - path: "lib/presentation/screens/attendance/widgets/student_justification_modal.dart"
      provides: "Kompaktowy modal prośby ucznia z przewijaną treścią i przypiętym na dole przyciskiem Wyślij prośbę do rodzica"
    - path: "lib/presentation/screens/attendance/justification_modal.dart"
      provides: "Kompaktowy modal usprawiedliwienia rodzica z przewijaną treścią i przypiętym na dole przyciskiem Zatwierdź i wyślij"
    - path: "lib/presentation/screens/attendance/widgets/parent_approval_modal.dart"
      provides: "Kompaktowy modal akceptacji prośby przez rodzica z przypiętym przyciskiem Zatwierdź z PIN-em"
---

<objective>
Naprawa układu modala prośby o usprawiedliwienie (`StudentJustificationModal`) oraz pozostałych modali usprawiedliwień w widoku frekwencji, tak aby na ekranach mobilnych (np. u Oskara) niebieski przycisk zatwierdzenia (`Wyślij prośbę do rodzica` / `Zatwierdź i wyślij`) był zawsze widoczny na dole ekranu, zawartość formularza była bardziej kompaktowa i przewijana, a modal nie był zasłaniany przez dolny pasek nawigacji ani przycisk `Czat & AI`.
</objective>

<tasks>

<task type="auto">
  <name>Task 1: Przebudowa modali usprawiedliwień na układ ze stałym nagłówkiem, przewijanym formularzem i przypiętą stopką</name>
  <files>
    lib/presentation/screens/attendance/widgets/student_justification_modal.dart
    lib/presentation/screens/attendance/justification_modal.dart
    lib/presentation/screens/attendance/widgets/parent_approval_modal.dart
    lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart
    lib/presentation/screens/attendance/widgets/student_response_modal.dart
  </files>
  <action>
    1. We wszystkich 5 modalach (`StudentJustificationModal.show`, `JustificationModal.show`, `ParentApprovalModal.show`, `ParentRejectionModal.show`, `StudentResponseModal.show`) dodaj `useRootNavigator: true` do `showModalBottomSheet`, aby arkusz wyświetlał się ponad dolnym paskiem nawigacji (`BottomNavigationBar`) i pływającym przyciskiem `Czat & AI`.
    2. Ogranicz maksymalną wysokość arkusza przez `ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88))` i uwzględnij `MediaQuery.of(context).viewInsets.bottom` + `MediaQuery.of(context).viewPadding.bottom`.
    3. Podziel `Column(mainAxisSize: MainAxisSize.min)` w każdym modalu na 3 sekcje:
       - Stały nagłówek (uchwyt przeciągania + ikona i tytuł).
       - `Flexible(child: SingleChildScrollView(child: Column(...)))` z polami formularza (daty, szybkie powody, pole tekstowe, pasek informacyjny) oraz bardziej kompaktowymi odstępami pionowymi i `FilterChip`/`ActionChip` o mniejszym `visualDensity`.
       - Stała dolna stopka z przyciskiem głównym (`FilledButton.icon`) oraz `TextButton` (`Anuluj`), zawsze widoczna na dole modala bez konieczności przewijania.
  </action>
  <verify>
    <automated>flutter analyze</automated>
  </verify>
  <done>Wszystkie 5 modali kompiluje się bez ostrzeżeń, posiada `useRootNavigator: true`, przewijaną sekcję środkową i przypięte przyciski akcji na dole.</done>
</task>

<task type="auto">
  <name>Task 2: Testy widoczności przycisku na małym ekranie mobilnym oraz wdrożenie</name>
  <files>
    test/attendance_justification_flow_test.dart
  </files>
  <action>
    1. Zaktualizuj `test/attendance_justification_flow_test.dart`, dodając test otwierający `StudentJustificationModal` na małym ekranie telefonu (np. `360x640`) i weryfikujący, że przycisk `Wyślij prośbę do rodzica` jest od razu widoczny i klikalny (`tester.tap` działa bez przewijania i bez błędów RenderFlex overflow).
    2. Uruchom `flutter test test/attendance_justification_flow_test.dart`.
    3. Zbuduj aplikację webową (`flutter build web --release`) i wdróż na Firebase Hosting.
  </action>
  <verify>
    <automated>flutter test test/attendance_justification_flow_test.dart</automated>
  </verify>
  <done>Testy przechodzą bez błędów, a poprawiona wersja działa na produkcji.</done>
</task>

</tasks>
