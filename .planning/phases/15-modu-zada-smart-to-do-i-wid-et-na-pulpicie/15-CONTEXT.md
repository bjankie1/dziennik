# Phase 15: Moduł zadań (Smart To-Do) i widżet na Pulpicie - Context

**Gathered:** 2026-09-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Faza 15 wdraża pełnoprawny, rodzinny moduł zarządzania zadaniami ucznia i rodzica (**Smart To-Do**) w czasie rzeczywistym z dedykowaną podstroną `/zadania` w menu nawigacyjnym oraz interaktywnym widżetem szybkiej listy zadań w Bento Grid na Pulpicie (`DashboardScreen`, desktop oraz mobile).

Wymagania fazy:
- `REQ-TASK-01`: Dedykowana podstrona `/zadania` w menu bocznym i nawigacji z wykazem zadań, terminami (`Due Date`), priorytetami, przypisaniem do roli oraz filtrami (`Wszystkie`, `Dzisiaj`, `Nadchodzące`, `Ukończone`).
- `REQ-TASK-02`: Karta Bento Grid na Pulpicie (desktop oraz mobile) prezentująca najpilniejsze zadania na dany dzień z natychmiastowym odhaczaniem jednym kliknięciem oraz szybkim dodawaniem zadań.

</domain>

<decisions>
## Implementation Decisions

### 1. Model zadań i współpraca Rodzic ↔ Uczeń (D-01, D-02, D-03)
- **D-01 (Przypisanie i atrybucja na wspólnej liście):**
  - Zadania są przechowywane we wspólnej kolekcji rodzinnej w Firestore (np. `family_tasks/{familyId}/tasks`, analogicznie do `family_chats/{familyId}/messages`) synchronizowanej w czasie rzeczywistym przez Riverpod `StreamProvider`.
  - Każde zadanie posiada przypisanie odbiorcy (`assignedTo`: `student` — „Dla Oskara”, `parent` — „Dla Rodzica”, `shared` — „Wspólne”) oraz pełny ślad atrybucji: kto utworzył zadanie (`createdByRole`, `createdByName`, `createdAt`) i kto je odhaczył (`completedByRole`, `completedByName`, `completedAt`), wyświetlane jako czytelna etykieta na karcie (np. *„Dodał: Tata • Ukończył: Oskar”*).
- **D-02 (Priorytety, przedmioty i gotowość pod Fazę 16):**
  - 3 poziomy priorytetu: `high` (Wysoki 🔴), `medium` (Normalny 🔵), `low` (Niski ⚪).
  - Opcjonalny tag przedmiotu szkolnego (np. *Matematyka*, *Biologia*, *J. polski*) lub kategorii (*Szkoła*, *Sprawdzian*, *Opłata/Formalności*, *Domowe*).
  - Pole `source` (`manual` | `exam` | `message`) oraz `sourceId` / `metadata` w modelu `SchoolTask`, przygotowujące strukturę pod automatyczne podpowiedzi ze sprawdzianów i wiadomości w Fazie 16 (`REQ-TASK-03`, `REQ-TASK-04`).
- **D-03 (Uprawnienia roli `student` vs `parent` i ochrona zadań zleconych przez Rodzica):**
  - Zarówno Rodzic, jak i Oskar mogą swobodnie dodawać, edytować i odhaczać zadania.
  - Jeżeli zadanie zostało utworzone przez Rodzica (`createdByRole == 'parent'`), na koncie ucznia (`isStudent == true`) akcja usunięcia zadania jest zablokowana/ukryta — Oskar może zadanie odhaczyć jako wykonane lub dopisać notatkę, ale nie może go skasować.

### 2. Układ i interakcja widoku `/zadania` w stylu listy Wiadomości (D-04, D-05, D-06)
- **D-04 (Wzorzec wizualny spójny z `MessagesScreen`):**
  - Widok `/zadania` (`TasksScreen`) zachowuje ten sam układ i estetykę co ekran Wiadomości (`MessagesScreen`):
    1. **Górny Segmented Control Bar** (`AppColors.surfaceContainerHigh.withValues(alpha: 0.6)`, `borderRadius: 16`) z zakładkami filtrów głównych: `Wszystkie`, `Dzisiaj`, `Nadchodzące`, `Ukończone` oraz dynamicznymi licznikami badge.
    2. **Wiersz paska akcji i szybkiego dodawania (`Quick Add` + `+ Nowe zadanie`):** Po lewej stronie pole tekstowe `Quick Add` / wyszukiwarki (wpisanie tytułu + szybkie pigułki wyboru terminu *Dzisiaj/Jutro*, priorytetu i odbiorcy *Oskar/Rodzic/Wspólne* + zatwierdzenie Enterem), a po prawej główny przycisk `FilledButton.icon` (`+ Nowe zadanie`, `AppColors.primary`, `borderRadius: 14`) otwierający pełny modal tworzenia/edycji zadania (`TaskFormModal`).
    3. **Dodatkowe pigułki szybkiego filtrowania przypisania:** Pod paskiem akcji kompaktowy rząd chipów: `Wszystkie`, `Dla Oskara`, `Dla Rodzica`, `Wspólne`.
- **D-05 (Sekcje chronologiczne na liście):**
  - Wewnątrz wybranej zakładki karty zadań są pogrupowane w czytelne sekcje nagłówkowe: **„Zaległe”** (wyróżnione kolorem `AppColors.error`), **„Dzisiaj”**, **„Jutro / Nadchodzące”** oraz **„Bez terminu”** (a w zakładce *Ukończone* posortowane wg daty ukończenia).
- **D-06 (Karty zadań i edycja w modalu):**
  - Jednokolumnowa lista kart (`AppColors.surfaceContainerLowest`, `borderRadius: 16`, delikatny cień) z interaktywnym checkboxem po lewej stronie, tytułem, opcjonalnym opisem, pigułkami priorytetu/przedmiotu/terminu/roli oraz stopką autora. Kliknięcie w kartę otwiera modal szczegółów i edycji zadania (`TaskFormModal`).

### 3. Widżet zadań na Pulpicie (`DashboardScreen` Bento Grid & Mobile) (D-07, D-08)
- **D-07 (Umiejscowienie na górze Kolumny 2 nad Wiadomościami):**
  - W 3-kolumnowym układzie Bento Grid na desktopie (`_buildDesktopMessagesColumn` — środkowa, najszersza kolumna `flex: 5`) karta **„Zadania na dziś”** znajduje się **na samej górze Kolumny 2, bezpośrednio nad kartą „Wiadomości i Komunikaty”**.
  - Na widoku mobilnym (`_buildMobileDashboard`) widżet „Zadania na dziś” wyświetla się bezpośrednio pod Harmonogramem dnia (nad sekcją Wiadomości / Ostatnich ocen).
- **D-08 (Zawartość i interakcja widżetu na Pulpicie):**
  - Prezentuje do 4–5 najpilniejszych aktywnych zadań (w pierwszej kolejności *Zaległe* oraz *Na dzisiaj*, priorytetowo dla zalogowanej roli i wspólne).
  - Kliknięcie checkboxa natychmiast odhacza zadanie w Firestore z płynną animacją przekreślenia tekstu bez opuszczania Pulpitu.
  - Nagłówek karty zawiera szybki przycisk `+` (otwierający modal dodawania lub inline Quick Add) oraz link `Zobacz wszystkie (X) →` przenoszący do `/zadania`.

### 4. Nawigacja i Routing (`/zadania` vs `/czat` na desktopie i mobile) (D-09)
- **D-09 (Rozmieszczenie w `AppSidebar`, `NavigationBar` i `AppHeader`):**
  - W `go_router` (`lib/presentation/routes/app_router.dart`) dodana zostaje trasa `/zadania` jako osobny branch w `StatefulShellRoute.indexedStack`.
  - **Na desktopie (`AppSidebar`):** Obie pozycje — `Zadania` (z licznikiem aktywnych zadań na dziś/zaległych) oraz `Czat Rodzinny` (z licznikiem nieprzeczytanych wiadomości) — są widoczne jako pełnoprawne pozycje w bocznym pasku nawigacji.
  - **Na mobile (`MainNavigationScreen` + `AppHeader`):** W dolnym pasku `NavigationBar` znajduje się 6 głównych zakładek edukacyjnych: `Pulpit`, `Plan`, `Oceny`, `Frekwencja`, `Wiadomości`, `Zadania`. Natomiast `Czat Rodzinny` na mobile zostaje wyeksponowany jako ikona komunikatora z dynamicznym licznikiem badge w górnym pasku `AppHeader` (obok ikony powiadomień i awatara profilu — spójnie z `AppDesktopHeader`).

### Antigravity's Discretion
- Dokładny schemat dokumentu Firestore w kolekcji `family_tasks/{familyId}/tasks` wraz z regułami `firestore.rules` (autoryzacja zalogowanych członków rodziny).
- Zestaw domyślnych zadań startowych (fallback / seed), jeśli kolekcja w Firestore jest jeszcze pusta, prezentujących współpracę Rodzic ↔ Oskar.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Routing & Navigation Shell
- `lib/presentation/routes/app_router.dart` — Konfiguracja `StatefulShellRoute.indexedStack`, rejestracja brancha `/zadania` i `/czat`.
- `lib/presentation/screens/main_navigation_screen.dart` — Obsługa zakładek desktop (`AppSidebar`) vs mobile (`NavigationBar` + `AppHeader`).
- `lib/presentation/widgets/app_sidebar.dart` — Boczny pasek nawigacji na desktopie (dodanie pozycji „Zadania” z badge'em).
- `lib/presentation/widgets/app_header.dart` — Mobilny nagłówek aplikacji (dodanie ikony Czatu Rodzinnego z badge'em `chatUnreadCount`).
- `lib/presentation/widgets/app_desktop_header.dart` — Wzorzec ikony Czatu Rodzinnego w nagłówku desktopowym.

### UI Reference & Dashboard Bento Grid
- `lib/presentation/screens/messages/messages_screen.dart` — Wzorzec wizualny dla widoku `/zadania` (Segmented Control Bar, pasek wyszukiwania/akcji z przyciskiem `FilledButton.icon`, lista kart).
- `lib/presentation/screens/dashboard/dashboard_screen.dart` — Układ 3-kolumnowy Bento Grid na desktopie (`_buildDesktopMessagesColumn` — Kolumna 2) oraz widok mobilny (`_buildMobileDashboard`).

### Data & Real-Time Providers Pattern
- `lib/presentation/providers/family_chat_provider.dart` — Wzorzec repozytorium czasu rzeczywistego w Firestore (`family_chats/{familyId}/messages`) z `StreamProvider` i obsługą `familyId`.
- `lib/presentation/providers/auth_providers.dart` — Model `AppUser`, rozpoznawanie roli `isStudent` vs `isParent`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MessagesScreen` (`lib/presentation/screens/messages/messages_screen.dart`): Gotowy układ Segmented Control Bar + pasek akcji + karty z zaokrągleniem `16px` i kolorystyką `AppColors.surfaceContainerLowest`.
- `FamilyChatRepository` (`lib/presentation/providers/family_chat_provider.dart`): Sprawdzony wzorzec współdzielonej kolekcji rodzinnej w Firestore z kluczem `familyId` i natychmiastową reaktywnością `StreamProvider`.
- `AppHeader` & `AppDesktopHeader`: Gotowe komponenty nagłówków z obsługą ikon z `Badge` (`chatUnreadCount`).

### Established Patterns
- Wszystkie ścieżki nawigacyjne w `go_router` używają polskich nazw (`/pulpit`, `/plan-lekcji`, `/oceny`, `/frekwencja`, `/wiadomosci`, `/zadania`, `/czat`).
- Sprawdzanie uprawnień odbywa się przez `ref.watch(appUserProvider)?.isStudent ?? false`.

### Integration Points
- Nowy plik modelu `lib/domain/models/school_task.dart` i providera `lib/presentation/providers/tasks_provider.dart`.
- Nowy ekran `lib/presentation/screens/tasks/tasks_screen.dart` wraz z modalem `task_form_modal.dart`.
- Osadzenie widżetu `_buildDesktopTasksCard` na szczycie `_buildDesktopMessagesColumn` (Kolumna 2) oraz `_buildMobileTasksCard` w `_buildMobileDashboard` w `lib/presentation/screens/dashboard/dashboard_screen.dart`.

</code_context>

<specifics>
## Specific Ideas

- Widok `/zadania` powinien wyglądać i działać podobnie do widoku listy Wiadomości (`MessagesScreen`): na górze zaokrąglony pasek zakładek z licznikami badge, pod nim pasek szybkiego dodawania (`Quick Add`) z przyciskiem `+ Nowe zadanie` po prawej stronie, a poniżej czytelna lista kart zadań.
- Na Pulpicie desktopowym widżet „Zadania na dziś” ma znaleźć się w **Kolumnie 2 (środkowej) nad kartą Wiadomości i Komunikatów**.
- Na telefonie dolny pasek nawigacji ma mieścić 6 pozycji (`Pulpit`, `Plan`, `Oceny`, `Frekwencja`, `Wiadomości`, `Zadania`), a `Czat Rodzinny` na mobile ma być dostępny z ikony z badge'em w górnym nagłówku `AppHeader`.

</specifics>

<deferred>
## Deferred Ideas

- Automatyczne generowanie zadań przygotowawczych ze sprawdzianów i terminarza (`REQ-TASK-03`) oraz heurystyczne wykrywanie zadań/opłat w treści wiadomości Librusa (`REQ-TASK-04`) — zaplanowane na **Fazę 16**.

</deferred>

---

*Phase: 15-Moduł zadań (Smart To-Do) i widżet na Pulpicie*
*Context gathered: 2026-09-23*
