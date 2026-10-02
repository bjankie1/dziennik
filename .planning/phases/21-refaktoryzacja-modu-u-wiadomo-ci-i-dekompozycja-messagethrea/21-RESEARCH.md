# Phase 21: Refaktoryzacja monolitycznych widoków UI (>1 600 LOC), wspólne komponenty i optymalizacja granic przebudowy Riverpod - Research

**Researched:** 2026-04-21
**Domain:** Flutter / Riverpod UI Architecture, Widget Decomposition, Selective Rebuild Boundaries
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `REQ-ARCH-01` | Dekompozycja 3 największych monolitów UI (`message_thread_screen.dart` 2 060 LOC, `attendance_screen.dart` 1 952 LOC, `notification_settings_modal.dart` 1 643 LOC) do koordynatorów < 350 LOC oraz wyodrębnienie współdzielonego `JustificationRequestBanner` i `PolishDateFormatter`. | Kompleksowa mapa dekompozycji linia-po-linii dla wszystkich 3 plików docelowych, ekstrakcja logiki domenowej nadawców/DW do `MessageThread`, konsolidacja 3 zduplikowanych banerów usprawiedliwień (~935 LOC oszczędności) oraz ujednolicenie formatowania dat w języku polskim. |
| `REQ-ARCH-02` | Zastąpienie prywatnych metod pomocniczych `Widget _build*()` dedykowanymi klasami `StatelessWidget`/`ConsumerWidget` z konstruktorami `const` oraz zawężenie subskrypcji Riverpod za pomocą `.select(...)`. | Wzorce izolacji stanu lokalnego (`MessageReplyComposer`, `PendingTeacherAccordionBanner`, `TelegramChannelCard`) oraz selektorów Riverpod (`tasksStreamProvider.select(...)`, `teachersProvider.select(...)`, `notificationSettingsProvider.select(...)`) zapobiegające przebudowie całych drzew widżetów przy lokalnych interakcjach. |
</phase_requirements>

## Summary

Phase 21 targets the three largest monolithic presentation files in the codebase:
1. `lib/presentation/screens/messages/message_thread_screen.dart` (**2 060 LOC**, 18 private `_build*` / helper methods) [VERIFIED: lib/presentation/screens/messages/message_thread_screen.dart:1-2060]
2. `lib/presentation/screens/attendance/attendance_screen.dart` (**1 952 LOC**, 14 private `_build*` / modal methods) [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:1-1952]
3. `lib/presentation/widgets/modals/notification_settings_modal.dart` (**1 643 LOC**, single giant `build()` method + 5 private `_build*` helpers) [VERIFIED: lib/presentation/widgets/modals/notification_settings_modal.dart:1-1643]

In addition, identical or near-identical parent/student justification banners (~310 LOC each, ~935 LOC total) are duplicated across three separate files (`dashboard_mobile_view.dart`, `dashboard_metrics_column.dart`, and `attendance_screen.dart`), while an earlier extraction attempt in `lib/presentation/widgets/common/justification_approval_dialogs.dart` (312 LOC) sits completely unused (`0` imports across `lib/` and `test/`). Similarly, Polish date/weekday formatting arrays (`_weekdays`, `_monthsGenitive`) and Polish pluralization helpers are copy-pasted across 7 files.

**Primary recommendation:** Execute the refactoring in **4 independent, test-verified waves**:
1. **Wave 1 (Shared Foundations & Banner Consolidation):** Create `PolishDateFormatter` (`lib/core/utils/polish_date_formatter.dart`) and `JustificationRequestBanner` (`lib/presentation/widgets/common/justification_request_banner.dart`), replacing the 3 duplicated banner blocks in `DashboardMobileView`, `DashboardMetricsColumn`, and `AttendanceScreen` (retiring or re-exporting unused `justification_approval_dialogs.dart`).
2. **Wave 2 (`MessageThreadScreen` Decomposition + Domain Logic Move):** Move sender/CC parsing (`resolveSenderName`, `extractCcTeacherFromBody`, `looksLikeMessageWithAttachment`) to `MessageThread` domain model, extract 4 sub-widgets (`MessageThreadHeaderCard`, `MessageTaskBanner`, `MessageAccordionTile`, `MessageReplyComposer`) into `lib/presentation/screens/messages/widgets/`, and add `.select(...)` on `tasksStreamProvider` and `teachersProvider`.
3. **Wave 3 (`AttendanceScreen` Decomposition):** Extract 6 sub-widgets (`AttendanceSemesterKpiCard`, `PendingTeacherAccordionBanner`, `AttendanceFilterBar`, `AttendanceDayGroupCard`, `FloatingJustificationDock`, `RequestedAttendanceDetailsSheet`) into `lib/presentation/screens/attendance/widgets/`, reducing `attendance_screen.dart` to < 350 LOC.
4. **Wave 4 (`NotificationSettingsModal` Decomposition):** Extract 5 sub-widgets (`NotificationSectionCard`, `TelegramChannelCard` + `TelegramStepByStepGuide`, `WebPushChannelCard`, `NotificationCategoriesCard`, `NotificationAlertsHistoryTab`) into `lib/presentation/widgets/modals/notification_settings/` with granular `notificationSettingsProvider.select(...)` subscriptions, reducing `notification_settings_modal.dart` to < 350 LOC.

---

## Architectural Responsibility Map

| Capability / Concern | Primary Tier | Exclusive Responsibility | Must NOT Do |
|---|---|---|---|
| `MessageThread` (`lib/domain/models/message_thread.dart`) | Domain Model | Parsing sender display names (`resolveSenderName`), extracting CC teacher from Librus body (`extractCcTeacherFromBody`), attachment heuristics (`looksLikeMessageWithAttachment`) | Must NOT depend on Flutter widgets, `BuildContext`, or Riverpod |
| `PolishDateFormatter` (`lib/core/utils/polish_date_formatter.dart`) | Core Utility | Formatting Polish day headers (`Poniedziałek, 16 marca`), full dates (`16 marca 2026`), timestamps (`16.03.2026, 14:05`), and Polish noun pluralization (`lekcja/lekcje/lekcji`) | Must NOT hold mutable state or depend on `BuildContext` |
| `JustificationRequestBanner` (`lib/presentation/widgets/common/justification_request_banner.dart`) | Shared Presentation Widget | Rendering parent pending justification approval banner & student rejected banner across Dashboard (Mobile/Desktop) and AttendanceScreen | Must NOT duplicate modal logic already encapsulated in `ParentApprovalModal` and `ParentRejectionModal` |
| Screen Coordinators (`message_thread_screen.dart`, `attendance_screen.dart`, `notification_settings_modal.dart`) | Presentation Screen / Modal Coordinator (< 350 LOC each) | High-level `Scaffold` / `TabBar` layout, top-level routing/navigation, and coordinating shared selection IDs across child sections | Must NOT contain > 50 LOC inline `Widget _build*()` methods or hold ephemeral input state (like text controllers for nested forms) that forces full-screen rebuilds |
| Feature Sub-Widgets (`messages/widgets/*`, `attendance/widgets/*`, `modals/notification_settings/*`) | Presentation Leaf / Section Widgets (`StatelessWidget` / `ConsumerWidget` / `ConsumerStatefulWidget`) | Rendering a single cohesive UI section with `const` constructors and narrowly scoped `ref.watch(provider.select(...))` subscriptions | Must NOT alter or omit existing `ValueKey`s, `Tooltip` messages, or test-targeted Polish labels |

---

## Standard Stack

No new external dependencies are required or permitted for this phase. All refactoring uses the existing stack verified in `pubspec.yaml`:

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_riverpod` | `^3.2.1` | State management, `ConsumerWidget`, `ConsumerStatefulWidget`, and `.select(...)` rebuild optimization | Project standard (`pubspec.yaml` line 32: `flutter_riverpod: ^3.2.1`) [VERIFIED: pubspec.yaml:31-33] |
| `lucide_icons` | `^0.257.0` | Iconography across all extracted sub-widgets | Project standard (`pubspec.yaml` line 39: `lucide_icons: ^0.257.0`) [VERIFIED: pubspec.yaml:38-40] |
| `flutter_test` | SDK | Widget regression testing for decomposed screens and extracted components | Project standard (`pubspec.yaml` lines 53-54) [VERIFIED: pubspec.yaml:53-55] |

---

## Architecture Patterns

### Pattern 1: Decomposing `message_thread_screen.dart` (2 060 LOC → < 350 LOC Coordinator)

#### 1.1 Domain Model Extraction (`lib/domain/models/message_thread.dart`)
Currently, `MessageThreadScreen` embeds three pure string/domain parsing methods inside `_MessageThreadScreenState` [VERIFIED: lib/presentation/screens/messages/message_thread_screen.dart:41-75,149-158]:
- `_resolveSenderName(MessageThread thread, {String? overrideBody})` (lines 41–60)
- `_extractCcTeacherFromBody(String body)` (lines 62–75)
- `_looksLikeMessageWithAttachment(String text)` (lines 149–158)

**Action:** Move these directly onto `MessageThread` (and `Message`) in `lib/domain/models/message_thread.dart` as pure domain methods with unit test coverage:
- `String resolveSenderName({String? overrideBody})`
- `String? extractCcTeacherFromBody([String? overrideBody])`
- `static bool looksLikeMessageWithAttachment(String text)`

#### 1.2 Target File Structure (`lib/presentation/screens/messages/widgets/`)

```
lib/presentation/screens/messages/
├── message_thread_screen.dart                  # < 300 LOC Coordinator (Scaffold, AppBar, Google Drive orchestration, ListView)
└── widgets/
    ├── message_thread_header_card.dart         # ~120 LOC StatelessWidget (Subject, NOWA/Ważne badges, sender role chip, msg count pill)
    ├── message_task_banner.dart                # ~260 LOC ConsumerWidget (Linked task banner / AI task suggestion banner + quick-add/edit actions)
    ├── message_accordion_tile.dart             # ~460 LOC StatelessWidget (Collapsed/expanded message card + attachments section + Drive buttons)
    └── message_reply_composer.dart             # ~310 LOC ConsumerStatefulWidget (Self-contained reply box, recipient chips, teacher autocomplete, send handler)
```

#### 1.3 Line-by-Line Extraction Map for `message_thread_screen.dart`

| Source Lines in `message_thread_screen.dart` | Current Method / Block | Target File & Class | Rebuild & State Strategy |
|---|---|---|---|
| `41-75`, `149-158` | `_resolveSenderName`, `_extractCcTeacherFromBody`, `_looksLikeMessageWithAttachment` | `lib/domain/models/message_thread.dart` (`MessageThread`) | Pure domain methods; zero widget state. |
| `490-596` | Header `Container` inside `build()` | `widgets/message_thread_header_card.dart` (`MessageThreadHeaderCard`) | `const StatelessWidget` taking `MessageThread thread`. |
| `329-415`, `617-874` | `_buildCurrentSuggestion`, `_openTaskModalFromMessage`, `_quickAddTaskFromMessage`, `_buildMessageTaskBanner` | `widgets/message_task_banner.dart` (`MessageTaskBanner` + `MessageAppBarTaskAction`) | `const ConsumerWidget` watching `tasksStreamProvider.select((asyncVal) => asyncVal.value?.where((t) => t.matchesMessage(thread.id)).firstOrNull)`. |
| `876-1362` | `_buildMessageItem`, `_buildCollapsedMessage`, `_buildExpandedMessage`, `_buildAttachmentsSection`, `_attachmentIconAndColor` | `widgets/message_accordion_tile.dart` (`MessageAccordionTile`) | `const StatelessWidget` receiving `Message message`, `bool isExpanded`, `Set<String> savingToDrive`, `Map<String, String> driveFileLinks`, and callbacks (`onToggle`, `onDownloadAttachment`, `onSaveToDrive`, `onSaveAllToDrive`, `onOpenDriveLink`). |
| `261-327`, `1759-2058` | `_handleSendReply`, `_buildReplySection` + fields `_isReplying`, `_isSending`, `_replyRecipients`, `_replyController`, `_replyFocusNode` | `widgets/message_reply_composer.dart` (`MessageReplyComposer`) | `const ConsumerStatefulWidget` owning its own `TextEditingController`, `FocusNode`, `_isReplying`, `_isSending`, and `_replyRecipients`. Watches `teachersProvider.select((a) => a.value ?? const <String>[])`. Typing or toggling recipients **never** rebuilds the message list! |

---

### Pattern 2: Decomposing `attendance_screen.dart` (1 952 LOC → < 350 LOC Coordinator)

#### 2.1 Target File Structure (`lib/presentation/screens/attendance/widgets/`)

```
lib/presentation/screens/attendance/
├── attendance_screen.dart                          # < 320 LOC Coordinator (Scaffold, data grouping, selection set, Stack layout)
└── widgets/
    ├── attendance_semester_kpi_card.dart           # ~230 LOC StatelessWidget (DualRingAttendanceGauge + 3 KPI columns + legend)
    ├── pending_teacher_accordion_banner.dart       # ~370 LOC ConsumerStatefulWidget (Collapsible amber banner for teacher-pending items + cancel single/all)
    ├── attendance_filter_bar.dart                  # ~120 LOC StatelessWidget (Horizontal filter chips + section header + Select/Deselect all toggle)
    ├── attendance_day_group_card.dart              # ~250 LOC StatelessWidget (Day header badge + AttendanceLessonRow items with selection checkboxes)
    ├── floating_justification_dock.dart            # ~230 LOC ConsumerStatefulWidget (Bottom sticky dock, quick reason chips, Submit / Request Parent actions)
    └── requested_attendance_details_sheet.dart     # ~180 LOC ConsumerStatefulWidget (Bottom sheet for single pending-teacher item details & cancellation)
```
*(Note: `parent_approval_modal.dart` and `parent_rejection_modal.dart` already exist in `lib/presentation/screens/attendance/widgets/` and remain intact).* [VERIFIED: lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:1-30]

#### 2.2 Line-by-Line Extraction Map for `attendance_screen.dart`

| Source Lines in `attendance_screen.dart` | Current Method / Block | Target File & Class | Rebuild & State Strategy |
|---|---|---|---|
| `38-71` | `_weekdays`, `_monthsGenitive`, `_formatDayHeader`, `_formatDatePl`, `_pluralLekcja` | `lib/core/utils/polish_date_formatter.dart` (`PolishDateFormatter`) | Shared static utility methods. |
| `420-661` | `_buildSemesterStatusCard`, `_buildStatColumn`, `_buildLegendItem` | `widgets/attendance_semester_kpi_card.dart` (`AttendanceSemesterKpiCard`) | `const StatelessWidget` taking precomputed counts (`presentCount`, `unexcusedCount`, `excusedCount`, `lateCount`, `overallPct`, `sem1Pct`, `sem2Pct`). |
| `873-1243` | `_buildPendingTeacherAccordionBanner` + `_isPendingBannerExpanded`, `_isCancellingPending` | `widgets/pending_teacher_accordion_banner.dart` (`PendingTeacherAccordionBanner`) | `const ConsumerStatefulWidget` owning `_isPendingBannerExpanded` and `_isCancellingPending` locally. Expanding/collapsing the accordion only rebuilds this banner! |
| `1245-1554` | `_buildParentJustificationBanner` | `lib/presentation/widgets/common/justification_request_banner.dart` (`JustificationRequestBanner`) | Shared `ConsumerWidget` across Dashboard & Attendance. |
| `208-270`, `663-720` | Filter chips row + `_buildFilterChip` + section header (`Zaznacz wszystkie`) | `widgets/attendance_filter_bar.dart` (`AttendanceFilterBar`) | `const StatelessWidget` taking `currentFilter`, counts, `allUnexcusedSelected`, `onFilterChanged`, `onToggleSelectAll`. |
| `299-389`, `722-871` | Day group container + `_buildAbsenceRow` | `widgets/attendance_day_group_card.dart` (`AttendanceDayGroupCard` + `AttendanceLessonRow`) | `const StatelessWidget` taking `dateKey`, `List<Attendance> items`, `Set<String> selectedIds`, `Set<String> pendingRequestIds`, `bool isReadOnly`, and callbacks. |
| `29-36`, `1556-1779` | `_quickReasons`, `_selectedQuickReason`, `_buildFloatingJustificationDock` | `widgets/floating_justification_dock.dart` (`FloatingJustificationDock`) | `const ConsumerStatefulWidget` owning `_selectedQuickReason`. Selecting a quick reason chip only rebuilds the dock. |
| `1781-1950` | `_showRequestedDetailsModal` | `widgets/requested_attendance_details_sheet.dart` (`RequestedAttendanceDetailsSheet`) | `const ConsumerStatefulWidget` with static `show(BuildContext context, Attendance item)` helper. |

---

### Pattern 3: Decomposing `notification_settings_modal.dart` (1 643 LOC → < 350 LOC Coordinator)

#### 3.1 Target File Structure (`lib/presentation/widgets/modals/notification_settings/`)

```
lib/presentation/widgets/modals/
├── notification_settings_modal.dart                         # < 300 LOC Coordinator (Dialog shell, header, TabBar, TabBarView, bottom Save bar)
└── notification_settings/
    ├── notification_section_card.dart                       # ~110 LOC StatelessWidget (Reusable card header + switch + animated body wrapper)
    ├── telegram_channel_card.dart                           # ~450 LOC ConsumerStatefulWidget (Telegram toggle, 6-digit pairing code, advanced @BotFather fields, test ping)
    ├── telegram_step_by_step_guide.dart                     # ~260 LOC StatelessWidget (Collapsible 4-step @BotFather guide + copy / open URL helpers)
    ├── web_push_channel_card.dart                           # ~140 LOC ConsumerWidget (Browser Web Push toggle + test push button)
    ├── notification_categories_card.dart                    # ~130 LOC ConsumerWidget (Event category switches: Grades, Homework, Messages, Announcements, AI Morning)
    └── notification_alerts_history_tab.dart                 # ~200 LOC ConsumerWidget (History list of sent alerts + Clear history action)
```

#### 3.2 Line-by-Line Extraction Map for `notification_settings_modal.dart`

| Source Lines in `notification_settings_modal.dart` | Current Method / Block | Target File & Class | Rebuild & State Strategy |
|---|---|---|---|
| `1269-1362` | `_buildSectionCard` | `notification_settings/notification_section_card.dart` (`NotificationSectionCard`) | `const StatelessWidget`. |
| `81-208`, `300-886` | Telegram controllers, `_testTelegramConnection`, `_generatePairingCode`, and Telegram `_buildSectionCard` block | `notification_settings/telegram_channel_card.dart` (`TelegramChannelCard`) | `const ConsumerStatefulWidget` watching `notificationSettingsProvider.select((s) => (enabled: s.telegramEnabled, token: s.telegramBotToken, chatId: s.telegramChatId))`. Owns its own `TextEditingController`s and pairing timer. |
| `1395-1641` | `_buildTelegramStepByStepGuide`, `_buildGuideStepItem` | `notification_settings/telegram_step_by_step_guide.dart` (`TelegramStepByStepGuide`) | `const StatelessWidget` with `VoidCallback onShowTokenFields`. |
| `210-258`, `890-1004` | `_testWebPushNotification` and Web Push `_buildSectionCard` block | `notification_settings/web_push_channel_card.dart` (`WebPushChannelCard`) | `const ConsumerWidget` watching `notificationSettingsProvider.select((s) => s.webPushEnabled)`. |
| `1008-1071`, `1364-1393` | Categories `Container` and `_buildCategoryToggle` | `notification_settings/notification_categories_card.dart` (`NotificationCategoriesCard`) | `const ConsumerWidget` watching `notificationSettingsProvider.select((s) => (grades: s.notifyGrades, homework: s.notifyHomework, messages: s.notifyMessages, announcements: s.notifyAnnouncements, morning: s.notifyMorningBriefing))`. |
| `1076-1267` | `_buildAlertsHistoryTab` | `notification_settings/notification_alerts_history_tab.dart` (`NotificationAlertsHistoryTab`) | `const ConsumerWidget` watching `notificationHistoryProvider`. |

---

### Pattern 4: Consolidating the 3 Duplicated Justification Banners (`JustificationRequestBanner`)

Currently, the exact same Parent Pending / Student Rejected justification banner UI is implemented in **three active files** (plus one unused file):
1. `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` (lines 292–620, `_buildJustificationBanner` + `_showApprovalDialog` + `_showRejectDialog` — **329 LOC**) [VERIFIED: lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart:292-620]
2. `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` (lines 336–347 and 547–852, `_buildJustificationBanner` — **317 LOC**) [VERIFIED: lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart:547-852]
3. `lib/presentation/screens/attendance/attendance_screen.dart` (lines 141–151 and 1245–1554, `_buildParentJustificationBanner` — **320 LOC**) [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:1245-1554]
4. `lib/presentation/widgets/common/justification_approval_dialogs.dart` (lines 1–312 — **unused file**, `0` imports in `lib/` and `test/`, and uses an older dialog implementation instead of `ParentApprovalModal` / `ParentRejectionModal`) [VERIFIED: lib/presentation/widgets/common/justification_approval_dialogs.dart:1-35]

#### Unified Widget Design (`lib/presentation/widgets/common/justification_request_banner.dart`)
Create `JustificationRequestBanner` as a `const ConsumerWidget`:
- Watches `justificationRequestProvider` and `authRoleProvider` internally (or accepts optional overrides).
- Supports a `bool showDetailsLink` parameter:
  - `true` on Dashboard (`DashboardMobileView` and `DashboardMetricsColumn`): displays the `'Zobacz szczegóły →'` link and makes the card clickable via `onNavigateToAttendance` (`() => ref.read(selectedNavIndexProvider.notifier).setIndex(4)`).
  - `false` on `AttendanceScreen`: hides `'Zobacz szczegóły →'` since the user is already on the Attendance screen, and attaches `key: const ValueKey('parent_pending_request_banner')` for test compatibility [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:1257].
- Delegates "Zatwierdź (PIN)" and "Odrzuć" actions directly to `ParentApprovalModal.show(context, req)` and `ParentRejectionModal.show(context, req)` (eliminating the inline `_showApprovalDialog` / `_showRejectDialog` methods still lingering in `dashboard_mobile_view.dart:495-620`).
- Update or remove `lib/presentation/widgets/common/justification_approval_dialogs.dart` (re-exporting `justification_request_banner.dart` if kept for backwards compatibility).

---

### Pattern 5: Shared `PolishDateFormatter` (`lib/core/utils/polish_date_formatter.dart`)

Currently, Polish date formatting arrays and pluralization functions are duplicated across:
- `lib/presentation/screens/attendance/attendance_screen.dart` (lines 38–71: `_weekdays`, `_monthsGenitive`, `_formatDayHeader`, `_formatDatePl`, `_pluralLekcja`) [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:38-71]
- `lib/domain/models/justification_request.dart` (lines 324–351: `weekdays`, `monthsGenitive`, `formatPolishDayHeader`) [VERIFIED: lib/domain/models/justification_request.dart:324-351]
- `lib/presentation/screens/grades/grades_screen.dart` (lines 81–98: `_polishMonths`, `_formatPolishDate`) [VERIFIED: lib/presentation/screens/grades/grades_screen.dart:81-98]
- `lib/presentation/screens/dashboard/dashboard_screen.dart` (lines 55–58: `days`, `months`) [VERIFIED: lib/presentation/screens/dashboard/dashboard_screen.dart:55-58]
- `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` (lines 47–50: `days`, `months`) [VERIFIED: lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart:47-50]

**Action:** Create `lib/core/utils/polish_date_formatter.dart` with `abstract final class PolishDateFormatter`:
- `static const List<String> weekdays` (`['Poniedziałek', ..., 'Niedziela']`)
- `static const List<String> monthsGenitive` (`['stycznia', ..., 'grudnia']`)
- `static String formatDayHeader(DateTime date)` → `'Poniedziałek, 16 marca'`
- `static String formatShortDayHeader(DateTime date)` → `'Poniedziałek, 16 marca'` (lowercase month, matching Dashboard greeting header)
- `static String formatFullDate(DateTime date)` → `'16 marca 2026'`
- `static String formatNumericDateTime(DateTime dt)` → `'16.03.2026, 14:05'`
- `static String formatNumericDateShortTime(DateTime dt)` → `'16.03, 14:05'`
- `static String pluralizeLesson(int count)` → `'1 lekcja'` / `'2 lekcje'` / `'5 lekcji'`
- Have `JustificationRequest.formatPolishDayHeader(DateTime date)` delegate directly to `PolishDateFormatter.formatDayHeader(date)`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Parent PIN verification & rejection modals in `DashboardMobileView` | Inline `AlertDialog` with manual PIN `TextEditingController` (`dashboard_mobile_view.dart:495-620`) | `ParentApprovalModal.show(context, req)` & `ParentRejectionModal.show(context, req)` (`lib/presentation/screens/attendance/widgets/`) | `ParentApprovalModal` and `ParentRejectionModal` already implement Librus dispatch, biometric/PIN check, loading spinners, and error handling [VERIFIED: lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:11-25]. |
| Full-provider `ref.watch` inside leaf widgets | `final allTasks = ref.watch(tasksStreamProvider).value ?? [];` in `MessageThreadScreen.build` | `ref.watch(tasksStreamProvider.select((asyncVal) => ...))` inside `MessageTaskBanner` | Prevents unrelated task edits from rebuilding the entire message thread and attachment list. |
| Custom date formatting arrays per screen | Local `const _weekdays = [...]` and `const _monthsGenitive = [...]` in every screen | `PolishDateFormatter` (`lib/core/utils/polish_date_formatter.dart`) | Single source of truth for Polish grammatical forms and zero duplication. |

---

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| **Stored data** | None — Firestore collections (`justification_requests`, `messages`, `attendance`, `tasks`) and `SharedPreferences` keys (`notif_telegram_enabled`, `notif_web_push_enabled`, `justification_request_v1`, etc.) are unchanged. | None — preserve existing provider storage keys. |
| **Live service / background state** | `NotificationSettingsNotifier` and `JustificationRequestNotifier` in Riverpod providers remain unchanged in signature and behavior. | None — UI refactoring only narrows `ref.watch` subscriptions via `.select(...)`. |
| **OS-registered state** | None. | None. |
| **Secrets / env vars** | None. | None. |
| **Build artifacts / dead files** | `lib/presentation/widgets/common/justification_approval_dialogs.dart` is an unused 312-LOC file from an earlier partial extraction (`0` references in `lib/` and `test/`). | Delete or convert into a barrel re-exporting `justification_request_banner.dart` so no dead duplicate remains. |

---

## Common Pitfalls

### Pitfall 1: Breaking Widget Tests by Altering `ValueKey`s or Polish Labels
**What goes wrong:** Decomposing widgets often tempts developers to rename keys or tweak button strings, causing existing widget tests to fail.
**Why it happens:** The test suite relies on specific `ValueKey`s and exact Polish text/tooltip strings.
**How to avoid:** Every extracted sub-widget **must** preserve the exact keys and text selectors verified in `test/`:

1. **`MessageAccordionTile` (`test/message_attachments_test.dart`)** [VERIFIED: test/message_attachments_test.dart:123-295]:
   - `const ValueKey('save_all_drive_button')` [VERIFIED: lib/presentation/screens/messages/message_thread_screen.dart:1119]
   - `ValueKey('download_attachment_$file')` [VERIFIED: lib/presentation/screens/messages/message_thread_screen.dart:1211]
   - `ValueKey('drive_spinner_$file')` [VERIFIED: lib/presentation/screens/messages/message_thread_screen.dart:1262]
   - `ValueKey('open_drive_$file')` [VERIFIED: lib/presentation/screens/messages/message_thread_screen.dart:1275]
   - `ValueKey('save_drive_$file')` [VERIFIED: lib/presentation/screens/messages/message_thread_screen.dart:1311]
   - Texts/Tooltips: `'Załączniki (${message.attachments.length}):'`, `'Zapisz wszystkie na Dysku'`, `'Zapisano wszystkie na Dysku'`, `'Zapisz na Dysku Google'`, `'Otwórz w Google Drive'`, `'Zmień folder / Przenieś'`.

2. **`PendingTeacherAccordionBanner` & `RequestedAttendanceDetailsSheet` (`test/attendance_pending_requests_test.dart`)** [VERIFIED: test/attendance_pending_requests_test.dart:140-260]:
   - `const ValueKey('pending_teacher_banner_toggle')` [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:895]
   - `const ValueKey('cancel_all_pending_button')` [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:957]
   - `const ValueKey('confirm_cancel_all_pending_button')` [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:978]
   - `ValueKey('cancel_pending_${rec.id}')` [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:1157]
   - `const ValueKey('close_requested_details_modal_button')` [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:1929]
   - Texts: `'${pendingList.length} ${pendingList.length == 1 ? "wniosek czeka" : "wnioski czekają"} na wychowawcę'`, `'Pokaż szczegóły'`, `'Ukryj szczegóły'`, `'Cofnij wszystkie'`, `'Cofnąć wszystkie oczekujące wnioski?'`, `'Oczekuje na wychowawcę w Librusie'`, `'Do usprawiedliwienia (${unexcused.length})'`, `'Oczekujące (${pendingList.length})'`.

3. **`JustificationRequestBanner` (`test/attendance_justification_modal_test.dart`)** [VERIFIED: test/attendance_justification_modal_test.dart:140-220]:
   - `const ValueKey('parent_pending_request_banner')` [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:1257]
   - Texts: `'$studentName prosi o usprawiedliwienie'`, `'Zatwierdź (PIN)'`, `'Odrzuć'`, `'Zobacz szczegóły →'` (when on Dashboard).

4. **`TelegramChannelCard` & `TelegramStepByStepGuide` (`test/presentation/widgets/notification_settings_modal_test.dart`)** [VERIFIED: test/presentation/widgets/notification_settings_modal_test.dart:30-150]:
   - `const ValueKey('telegram_step_by_step_guide_button')` [VERIFIED: lib/presentation/widgets/modals/notification_settings_modal.dart:664]
   - `const ValueKey('telegram_guide_show_token_field_button')` [VERIFIED: lib/presentation/widgets/modals/notification_settings_modal.dart:1492]
   - Texts: `'Instrukcja krok po kroku (Jak połączyć?)'`, `'Instrukcja krok po kroku: Jak skonfigurować powiadomienia Telegram'`, `'Krok 1'`, `'Krok 2'`, `'Krok 3'`, `'Krok 4'`, `'Kopiuj /newbot'`, `'Otwórz @BotFather'`, `'Invalid bot passed'`, `'Telegram Bot Token (@BotFather)'`.

### Pitfall 2: Losing Pending Unsaved Text in `NotificationSettingsModal` Bottom "Zapisz ustawienia" Button
**What goes wrong:** In `NotificationSettingsModal`, the bottom bar has a `"Zapisz ustawienia"` button (`lines 1252-1261`) that saves the current text from `_botTokenController` and `_chatIdController` before closing the modal [VERIFIED: lib/presentation/widgets/modals/notification_settings_modal.dart:260-269,1252-1261]. If those `TextEditingController`s are moved inside `TelegramChannelCard` without syncing or exposing their values, clicking `"Zapisz ustawienia"` at the modal bottom won't persist unsubmitted edits in the text fields.
**How to avoid:** Either:
1. Update `notificationSettingsProvider.notifier.setTelegramBotToken(val)` / `setTelegramChatId(val)` on `onChanged` (already done on lines 725–727 and 753–755! [VERIFIED: lib/presentation/widgets/modals/notification_settings_modal.dart:725-755]), OR
2. Pass a `GlobalKey<TelegramChannelCardState>` / callback so the modal's `"Zapisz ustawienia"` button flushes any trimmed controller values before popping. (Note: Because `onChanged` already updates `notificationSettingsProvider` live on every keystroke, keeping `onChanged` + flushing trimmed values on save guarantees 100% parity).

### Pitfall 3: `ref.watch(provider.select(...))` Returning Non-Equatable Collections
**What goes wrong:** Using `.select((state) => state.items.where(...).toList())` creates a new `List` instance on every evaluation. Because Dart's `List` uses identity equality (`==`), Riverpod thinks the selected value changed every time and triggers a rebuild anyway.
**How to avoid:**
- Select a single nullable object (`firstOrNull`), primitive (`bool`, `int`, `String`), Dart 3 Record of primitives (`(enabled: s.telegramEnabled, token: s.telegramBotToken, chatId: s.telegramChatId)` — Dart 3 records have structural value equality!), or an immutable reference (`asyncVal.value` directly without `.toList()`).

---

## Code Examples

### 1. Dart 3 Record Selector with Riverpod `.select(...)`
```dart
// Inside NotificationCategoriesCard.build(BuildContext context, WidgetRef ref):
final categories = ref.watch(
  notificationSettingsProvider.select(
    (s) => (
      grades: s.notifyGrades,
      homework: s.notifyHomework,
      messages: s.notifyMessages,
      announcements: s.notifyAnnouncements,
      morningBriefing: s.notifyMorningBriefing,
    ),
  ),
);
// Dart 3 records compare fields by value automatically!
// Changes to telegramBotToken or pairingCode will NEVER rebuild NotificationCategoriesCard.
```

### 2. Selective Task Lookup in `MessageTaskBanner`
```dart
// Inside MessageTaskBanner.build(BuildContext context, WidgetRef ref):
final linkedTask = ref.watch(
  tasksStreamProvider.select((asyncTasks) {
    final list = asyncTasks.value;
    if (list == null) return null;
    for (final t in list) {
      if (t.matchesMessage(thread.id)) return t;
    }
    return null;
  }),
);
```

### 3. Unified `JustificationRequestBanner` Signature
```dart
class JustificationRequestBanner extends ConsumerWidget {
  final bool showDetailsLink;
  final VoidCallback? onNavigateToAttendance;

  const JustificationRequestBanner({
    super.key,
    this.showDetailsLink = false,
    this.onNavigateToAttendance,
  });
  // Renders parent pending banner (with ValueKey('parent_pending_request_banner'))
  // or student rejected banner, delegating modals to ParentApprovalModal & ParentRejectionModal.
}
```

---

## Validation Architecture

### Test Framework
- **Framework:** `flutter_test` (Flutter SDK)
- **Config file:** `pubspec.yaml` / `analysis_options.yaml`
- **Quick run command:**
  ```bash
  flutter test test/message_attachments_test.dart test/presentation/screens/messages_timestamp_test.dart test/attendance_pending_requests_test.dart test/attendance_justification_modal_test.dart test/dashboard_screen_test.dart test/presentation/widgets/notification_settings_modal_test.dart
  ```
- **Full suite & static analysis command:**
  ```bash
  flutter analyze && flutter test
  ```

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| `REQ-ARCH-01` | `message_thread_screen.dart`, `attendance_screen.dart`, `notification_settings_modal.dart` < 350 LOC each | Static check + Widget tests | `wc -l lib/presentation/screens/messages/message_thread_screen.dart lib/presentation/screens/attendance/attendance_screen.dart lib/presentation/widgets/modals/notification_settings_modal.dart` | ✅ |
| `REQ-ARCH-01` | `MessageThread` domain methods (`resolveSenderName`, `extractCcTeacherFromBody`, `looksLikeMessageWithAttachment`) | Unit + Widget test | `flutter test test/message_attachments_test.dart test/presentation/screens/messages_timestamp_test.dart` | ✅ |
| `REQ-ARCH-01` | Shared `JustificationRequestBanner` works across Dashboard & AttendanceScreen | Widget test | `flutter test test/attendance_justification_modal_test.dart test/dashboard_screen_test.dart` | ✅ |
| `REQ-ARCH-01` | Shared `PolishDateFormatter` formats day headers, dates, and lesson plurals | Unit test | `flutter test test/core/utils/polish_date_formatter_test.dart` | ❌ Wave 1 creates |
| `REQ-ARCH-02` | Extracted sub-widgets preserve all interactive behaviors and `ValueKey`s | Widget test | `flutter test test/attendance_pending_requests_test.dart test/presentation/widgets/notification_settings_modal_test.dart` | ✅ |

### Wave 0 / Wave 1 Test Additions
- Create `test/core/utils/polish_date_formatter_test.dart` in Wave 1 to unit-test `PolishDateFormatter.formatDayHeader`, `formatFullDate`, `formatNumericDateTime`, and `pluralizeLesson`.
- Add unit tests for `MessageThread.resolveSenderName` and `MessageThread.extractCcTeacherFromBody` in Wave 2.

---

## Security Domain

- **Applicable ASVS Categories:** None directly modified (pure UI decomposition and state-subscription narrowing).
- **Authentication / Parental Control Integrity:** `JustificationRequestBanner` MUST continue to enforce `ParentApprovalModal.show(context, req)` (which verifies the parent's 4-digit PIN / biometrics via `ParentPinService` before approving attendance justifications) and only render approval buttons when `authRoleProvider == UserRole.parent` [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:141-147].

---

## Sources

### Primary (HIGH confidence)
- `lib/presentation/screens/messages/message_thread_screen.dart` (lines 1–2060) — verified all 18 private methods, state variables, and Google Drive attachment keys [VERIFIED: lib/presentation/screens/messages/message_thread_screen.dart:1-2060]
- `lib/presentation/screens/attendance/attendance_screen.dart` (lines 1–1952) — verified all 14 private methods, pending banner keys, filter chips, and justification dock [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:1-1952]
- `lib/presentation/widgets/modals/notification_settings_modal.dart` (lines 1–1643) — verified tabs, Telegram pairing, step-by-step guide keys, Web Push, and categories [VERIFIED: lib/presentation/widgets/modals/notification_settings_modal.dart:1-1643]
- `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` (lines 292–620) & `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` (lines 547–852) — verified duplicated justification banners [VERIFIED: lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart:292-620]
- `test/message_attachments_test.dart`, `test/attendance_pending_requests_test.dart`, `test/attendance_justification_modal_test.dart`, `test/presentation/widgets/notification_settings_modal_test.dart`, `test/dashboard_screen_test.dart` — verified all test selectors and `ValueKey`s, and confirmed 100% pass rate with `flutter test`.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified in `pubspec.yaml`, zero new dependencies needed.
- Architecture & line-by-line decomposition: HIGH — every method, line range, and state field in all three target files was inspected and mapped.
- Pitfalls & test compatibility: HIGH — every `ValueKey` and text selector across the existing widget test suite was audited and documented.

**Research date:** 2026-04-21
**Valid until:** 2026-05-21
