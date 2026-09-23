import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/school_task.dart';
import '../../providers/auth_providers.dart';
import '../../providers/tasks_provider.dart';
import 'widgets/task_form_modal.dart';

/// Dedicated `/zadania` screen (`TasksScreen`) matching `MessagesScreen` visual pattern
/// (`REQ-TASK-01`, `D-01`, `D-02`, `D-03`, `D-04`, `D-05`, `D-06`).
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  // 0 = Wszystkie (aktywne), 1 = Dzisiaj (+ zaległe), 2 = Nadchodzące, 3 = Ukończone
  int _activeTab = 0;

  // null = Wszystkie role, otherwise specific TaskAssignee
  TaskAssignee? _selectedAssigneeFilter;

  // Quick Add state
  final TextEditingController _quickAddController = TextEditingController();
  bool _quickDueDateTomorrow = false;
  TaskPriority _quickPriority = TaskPriority.medium;
  TaskAssignee _quickAssignee = TaskAssignee.student;

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _submitQuickAdd() async {
    final trimmed = _quickAddController.text.trim();
    if (trimmed.isEmpty) return;

    final user = ref.read(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final familyId = user?.familyId ?? 'jankiewicz_family';
    final actorRole = isStudent ? 'student' : 'parent';
    final actorName = isStudent
        ? 'Oskar'
        : ((user?.displayName.trim().isNotEmpty ?? false)
            ? user!.displayName.trim()
            : 'Tata');

    final today = SchoolTask.todayStart;
    final dueDate =
        _quickDueDateTomorrow ? today.add(const Duration(days: 1)) : today;

    _quickAddController.clear();

    await ref.read(tasksRepositoryProvider).addTask(
          familyId: familyId,
          title: trimmed,
          dueDate: dueDate,
          priority: _quickPriority,
          assignedTo: _quickAssignee,
          createdByRole: actorRole,
          createdByName: actorName,
        );
  }

  void _cycleQuickPriority() {
    setState(() {
      _quickPriority = switch (_quickPriority) {
        TaskPriority.medium => TaskPriority.high,
        TaskPriority.high => TaskPriority.low,
        TaskPriority.low => TaskPriority.medium,
      };
    });
  }

  void _cycleQuickAssignee() {
    setState(() {
      _quickAssignee = switch (_quickAssignee) {
        TaskAssignee.student => TaskAssignee.parent,
        TaskAssignee.parent => TaskAssignee.shared,
        TaskAssignee.shared => TaskAssignee.student,
      };
    });
  }

  String _formatDueDatePill(SchoolTask task) {
    final d = task.normalizedDueDate;
    if (d == null) return 'Bez terminu';
    final today = SchoolTask.todayStart;
    final tomorrow = today.add(const Duration(days: 1));
    if (d.isAtSameMomentAs(today)) return 'Dzisiaj';
    if (d.isAtSameMomentAs(tomorrow)) return 'Jutro';
    try {
      return DateFormat('d MMM', 'pl_PL').format(d);
    } catch (_) {
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _handleToggleCompletion(SchoolTask task) async {
    final user = ref.read(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final familyId = user?.familyId ?? 'jankiewicz_family';
    final actorRole = isStudent ? 'student' : 'parent';
    final actorName = isStudent
        ? 'Oskar'
        : ((user?.displayName.trim().isNotEmpty ?? false)
            ? user!.displayName.trim()
            : 'Tata');

    try {
      await ref.read(tasksRepositoryProvider).toggleTaskCompletion(
            familyId,
            task,
            isCompleted: !task.isCompleted,
            actorRole: actorRole,
            actorName: actorName,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się zaktualizować statusu zadania: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteTask(SchoolTask task, bool isStudent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Usuń zadanie',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Usuń zadanie: Czy na pewno chcesz bezpowrotnie usunąć zadanie „${task.title}” ze wspólnej listy rodzinnej?',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń zadanie'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = ref.read(appUserProvider);
    final familyId = user?.familyId ?? 'jankiewicz_family';
    await ref.read(tasksRepositoryProvider).deleteTask(
          familyId,
          task,
          isStudent: isStudent,
        );
  }

  List<SchoolTask> _filterTasksForCurrentTab(List<SchoolTask> allTasks) {
    final roleFiltered = _selectedAssigneeFilter == null
        ? allTasks
        : allTasks
            .where((t) => t.assignedTo == _selectedAssigneeFilter)
            .toList();

    return switch (_activeTab) {
      0 => roleFiltered.where((t) => !t.isCompleted).toList(),
      1 => roleFiltered
          .where((t) => !t.isCompleted && (t.isOverdue || t.isDueToday))
          .toList(),
      2 => roleFiltered.where((t) => !t.isCompleted && t.isUpcoming).toList(),
      3 => roleFiltered.where((t) => t.isCompleted).toList()
        ..sort((a, b) => (b.completedAt ?? b.createdAt)
            .compareTo(a.completedAt ?? a.createdAt)),
      _ => roleFiltered.where((t) => !t.isCompleted).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final user = ref.watch(appUserProvider);
    final isStudent = user?.isStudent ?? false;

    final allTasks = tasksAsync.value ?? const [];

    // Badge counts for the 4 tabs (D-04.1)
    final activeAllCount = allTasks.where((t) => !t.isCompleted).length;
    final overdueCount =
        allTasks.where((t) => !t.isCompleted && t.isOverdue).length;
    final todayPlusOverdueCount = allTasks
        .where((t) => !t.isCompleted && (t.isDueToday || t.isOverdue))
        .length;
    final upcomingCount =
        allTasks.where((t) => !t.isCompleted && t.isUpcoming).length;
    final completedCount = allTasks.where((t) => t.isCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Top Segmented Control Bar (D-04.1)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    0,
                    icon: Icons.format_list_bulleted,
                    title: 'Wszystkie',
                    badgeCount: activeAllCount > 0 ? activeAllCount : null,
                    badgeColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    1,
                    icon: Icons.today,
                    title: 'Dzisiaj',
                    badgeCount: todayPlusOverdueCount > 0
                        ? todayPlusOverdueCount
                        : null,
                    badgeColor:
                        overdueCount > 0 ? AppColors.error : AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    2,
                    icon: Icons.upcoming_outlined,
                    title: 'Nadchodzące',
                    badgeCount: upcomingCount > 0 ? upcomingCount : null,
                    badgeColor: AppColors.tertiaryContainer,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    3,
                    icon: Icons.task_alt,
                    title: 'Ukończone',
                    badgeCount: completedCount > 0 ? completedCount : null,
                    badgeColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Action & Quick Add Row (Quick Add + '+ Nowe zadanie', D-04.2)
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x05000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quickAddController,
                          onSubmitted: (_) => _submitQuickAdd(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                          decoration: const InputDecoration(
                            hintText:
                                'Dodaj szybkie zadanie (np. Powtórka z biologii)...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: AppColors.outline,
                            ),
                            prefixIcon: Icon(
                              Icons.bolt_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      // Inline Quick toggles (Due Date, Priority, Assignee)
                      _buildQuickTogglePill(
                        label: _quickDueDateTomorrow ? 'Jutro' : 'Dzisiaj',
                        bgColor: AppColors.surfaceContainerLow,
                        fgColor: AppColors.onSurfaceVariant,
                        onTap: () => setState(
                          () => _quickDueDateTomorrow = !_quickDueDateTomorrow,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildQuickTogglePill(
                        label: switch (_quickPriority) {
                          TaskPriority.high => '🔴',
                          TaskPriority.medium => '🔵',
                          TaskPriority.low => '⚪',
                        },
                        bgColor: switch (_quickPriority) {
                          TaskPriority.high => AppColors.errorContainer,
                          TaskPriority.medium => AppColors.primaryFixed,
                          TaskPriority.low => AppColors.surfaceContainerLow,
                        },
                        fgColor: AppColors.onSurface,
                        onTap: _cycleQuickPriority,
                      ),
                      const SizedBox(width: 4),
                      _buildQuickTogglePill(
                        label: switch (_quickAssignee) {
                          TaskAssignee.student => 'Oskar',
                          TaskAssignee.parent => 'Rodzic',
                          TaskAssignee.shared => 'Wspólne',
                        },
                        bgColor: switch (_quickAssignee) {
                          TaskAssignee.student => AppColors.primaryFixed,
                          TaskAssignee.parent => AppColors.tertiaryFixed,
                          TaskAssignee.shared => AppColors.secondaryContainer,
                        },
                        fgColor: AppColors.onSurface,
                        onTap: _cycleQuickAssignee,
                      ),
                      IconButton(
                        tooltip: 'Dodaj szybkie zadanie',
                        onPressed: _submitQuickAdd,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: () => TaskFormModal.show(context),
                  icon: const Icon(Icons.add_task, size: 18),
                  label: const Text(
                    '+ Nowe zadanie',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Role Filter Chip Row (D-04.3)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleFilterChip(
                  assignee: null,
                  label: 'Wszystkie',
                  icon: Icons.filter_list_rounded,
                ),
                const SizedBox(width: 8),
                _buildRoleFilterChip(
                  assignee: TaskAssignee.student,
                  label: 'Dla Oskara',
                  icon: Icons.school_outlined,
                ),
                const SizedBox(width: 8),
                _buildRoleFilterChip(
                  assignee: TaskAssignee.parent,
                  label: 'Dla Rodzica',
                  icon: Icons.verified_user_outlined,
                ),
                const SizedBox(width: 8),
                _buildRoleFilterChip(
                  assignee: TaskAssignee.shared,
                  label: 'Wspólne',
                  icon: Icons.people_outline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Chronological Sections & Task Cards (D-05, D-06)
          tasksAsync.when(
            data: (tasks) {
              final visibleTasks = _filterTasksForCurrentTab(tasks);
              if (visibleTasks.isEmpty) {
                return _buildEmptyState();
              }

              // Completed tab (sorted descending by completedAt ?? createdAt)
              if (_activeTab == 3) {
                return Column(
                  children: visibleTasks
                      .map((t) => _buildTaskCard(t, isStudent: isStudent))
                      .toList(),
                );
              }

              // Active tabs: group into non-empty chronological sections (D-05)
              final overdueList =
                  visibleTasks.where((t) => t.isOverdue).toList();
              final todayList =
                  visibleTasks.where((t) => t.isDueToday).toList();
              final upcomingList =
                  visibleTasks.where((t) => t.isUpcoming).toList();
              final noDateList =
                  visibleTasks.where((t) => t.hasNoDueDate).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (overdueList.isNotEmpty) ...[
                    _buildSectionHeader(
                      title: 'Zaległe',
                      count: overdueList.length,
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.error,
                      badgeBg: AppColors.errorContainer,
                      badgeFg: AppColors.onErrorContainer,
                    ),
                    ...overdueList.map(
                      (t) => _buildTaskCard(t, isStudent: isStudent),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (todayList.isNotEmpty) ...[
                    _buildSectionHeader(
                      title: 'Dzisiaj',
                      count: todayList.length,
                      icon: Icons.wb_sunny_outlined,
                      color: AppColors.onSurface,
                      badgeBg: AppColors.primaryFixed,
                      badgeFg: AppColors.onPrimaryFixedVariant,
                    ),
                    ...todayList.map(
                      (t) => _buildTaskCard(t, isStudent: isStudent),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (upcomingList.isNotEmpty) ...[
                    _buildSectionHeader(
                      title: 'Jutro / Nadchodzące',
                      count: upcomingList.length,
                      icon: Icons.calendar_month_outlined,
                      color: AppColors.onSurface,
                      badgeBg: AppColors.surfaceContainerHigh,
                      badgeFg: AppColors.onSurfaceVariant,
                    ),
                    ...upcomingList.map(
                      (t) => _buildTaskCard(t, isStudent: isStudent),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (noDateList.isNotEmpty) ...[
                    _buildSectionHeader(
                      title: 'Bez terminu',
                      count: noDateList.length,
                      icon: Icons.inbox_outlined,
                      color: AppColors.onSurfaceVariant,
                      badgeBg: AppColors.surfaceContainerLow,
                      badgeFg: AppColors.onSurfaceVariant,
                    ),
                    ...noDateList.map(
                      (t) => _buildTaskCard(t, isStudent: isStudent),
                    ),
                  ],
                ],
              );
            },
            loading: () => Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 40,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nie udało się pobrać listy zadań z chmury Firestore. Sprawdź połączenie z internetem i odśwież widok.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(tasksStreamProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Spróbuj ponownie'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    int index, {
    required IconData icon,
    required String title,
    int? badgeCount,
    required Color badgeColor,
  }) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTogglePill({
    required String label,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleFilterChip({
    required TaskAssignee? assignee,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedAssigneeFilter == assignee;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerLowest,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : AppColors.outlineVariant.withValues(alpha: 0.4),
      ),
      showCheckmark: false,
      onSelected: (_) => setState(() => _selectedAssigneeFilter = assignee),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color badgeBg,
    required Color badgeFg,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(SchoolTask task, {required bool isStudent}) {
    final canDelete = task.canBeDeletedBy(isStudent: isStudent);
    final borderColor = task.isOverdue
        ? AppColors.error.withValues(alpha: 0.4)
        : AppColors.outlineVariant.withValues(alpha: 0.3);

    return Opacity(
      opacity: task.isCompleted ? 0.72 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => TaskFormModal.show(context, existingTask: task),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Custom rounded Checkbox inside 44x44 tap area
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Checkbox(
                    value: task.isCompleted,
                    activeColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (_) => _handleToggleCompletion(task),
                  ),
                ),
                const SizedBox(width: 8),

                // Center: Title, optional description, metadata pills & attribution footer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: task.isCompleted
                              ? AppColors.outline
                              : AppColors.onSurface,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildPriorityPill(task.priority),
                          if (task.subject != null &&
                              task.subject!.isNotEmpty)
                            _buildMetadataPill(
                              label: task.subject!,
                              bgColor: AppColors.surfaceContainerLow,
                              fgColor: AppColors.primary,
                              icon: Icons.menu_book_outlined,
                            ),
                          if (task.dueDate != null)
                            _buildMetadataPill(
                              label: _formatDueDatePill(task),
                              bgColor: task.isOverdue
                                  ? AppColors.errorContainer
                                  : AppColors.surfaceContainerLow,
                              fgColor: task.isOverdue
                                  ? AppColors.onErrorContainer
                                  : AppColors.onSurfaceVariant,
                              icon: task.isOverdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.event_outlined,
                            ),
                          _buildAssigneePill(task.assignedTo),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.attributionLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Delete action or D-03 Parent Lock icon
                if (canDelete)
                  IconButton(
                    tooltip: 'Usuń zadanie',
                    onPressed: () => _confirmDeleteTask(task, isStudent),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.outline,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Tooltip(
                      message:
                          'Zadanie zlecone przez Rodzica — brak możliwości usunięcia',
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lock_person_outlined,
                          size: 16,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityPill(TaskPriority priority) {
    final (bgColor, fgColor, dotColor) = switch (priority) {
      TaskPriority.high => (
          AppColors.errorContainer,
          AppColors.onErrorContainer,
          AppColors.error,
        ),
      TaskPriority.medium => (
          AppColors.primaryFixed,
          AppColors.onPrimaryFixedVariant,
          AppColors.primary,
        ),
      TaskPriority.low => (
          AppColors.surfaceContainerLow,
          AppColors.onSurfaceVariant,
          AppColors.outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneePill(TaskAssignee assignee) {
    final (bgColor, fgColor, icon) = switch (assignee) {
      TaskAssignee.student => (
          AppColors.primaryFixed,
          AppColors.onPrimaryFixed,
          Icons.school_outlined,
        ),
      TaskAssignee.parent => (
          AppColors.tertiaryFixed,
          AppColors.onTertiaryFixed,
          Icons.verified_user_outlined,
        ),
      TaskAssignee.shared => (
          AppColors.secondaryContainer,
          AppColors.onSecondaryFixedVariant,
          Icons.people_outline,
        ),
    };

    return _buildMetadataPill(
      label: assignee.label,
      bgColor: bgColor,
      fgColor: fgColor,
      icon: icon,
    );
  }

  Widget _buildMetadataPill({
    required String label,
    required Color bgColor,
    required Color fgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 44,
            color: AppColors.outline.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak zadań w tym widoku',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Wpisz tytuł w polu szybkiego dodawania powyżej lub kliknij „+ Nowe zadanie”, aby zaplanować naukę lub obowiązki dla Oskara i Rodzica.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
