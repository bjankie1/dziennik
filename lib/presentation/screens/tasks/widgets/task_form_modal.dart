import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/school_task.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/tasks_provider.dart';

/// Modal for creating, viewing, and editing a shared family task (`REQ-TASK-01`, `D-01`, `D-02`, `D-03`, `D-06`).
class TaskFormModal extends ConsumerStatefulWidget {
  final SchoolTask? existingTask;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialSubject;
  final TaskAssignee? initialAssignedTo;
  final TaskPriority? initialPriority;
  final DateTime? initialDueDate;
  final TaskSource? initialSource;
  final String? initialSourceId;
  final Map<String, dynamic>? initialMetadata;

  const TaskFormModal({
    super.key,
    this.existingTask,
    this.initialTitle,
    this.initialDescription,
    this.initialSubject,
    this.initialAssignedTo,
    this.initialPriority,
    this.initialDueDate,
    this.initialSource,
    this.initialSourceId,
    this.initialMetadata,
  });

  static Future<void> show(
    BuildContext context, {
    SchoolTask? existingTask,
    String? initialTitle,
    String? initialDescription,
    String? initialSubject,
    TaskAssignee? initialAssignedTo,
    TaskPriority? initialPriority,
    DateTime? initialDueDate,
    TaskSource? initialSource,
    String? initialSourceId,
    Map<String, dynamic>? initialMetadata,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: TaskFormModal(
            existingTask: existingTask,
            initialTitle: initialTitle,
            initialDescription: initialDescription,
            initialSubject: initialSubject,
            initialAssignedTo: initialAssignedTo,
            initialPriority: initialPriority,
            initialDueDate: initialDueDate,
            initialSource: initialSource,
            initialSourceId: initialSourceId,
            initialMetadata: initialMetadata,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends ConsumerState<TaskFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _subjectController;

  late TaskAssignee _assignedTo;
  late TaskPriority _priority;
  DateTime? _dueDate;
  bool _isSaving = false;

  static const List<String> _presetSubjects = [
    'Matematyka',
    'Biologia',
    'J. polski',
    'J. angielski',
    'Historia',
    'Chemia',
    'Fizyka',
    'Sprawdzian',
    'Opłata/Formalności',
    'Domowe',
  ];

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTask;
    _titleController = TextEditingController(
      text: existing?.title ?? widget.initialTitle ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? widget.initialDescription ?? '',
    );
    _subjectController = TextEditingController(
      text: existing?.subject ?? widget.initialSubject ?? '',
    );
    _assignedTo = existing?.assignedTo ??
        widget.initialAssignedTo ??
        TaskAssignee.student;
    _priority =
        existing?.priority ?? widget.initialPriority ?? TaskPriority.medium;
    _dueDate =
        existing?.dueDate ?? widget.initialDueDate ?? SchoolTask.todayStart;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  String _formatDateLabel(DateTime? date) {
    if (date == null) return 'Bez terminu';
    final normalized = DateTime(date.year, date.month, date.day);
    final today = SchoolTask.todayStart;
    final tomorrow = today.add(const Duration(days: 1));
    if (normalized.isAtSameMomentAs(today)) return 'Dzisiaj';
    if (normalized.isAtSameMomentAs(tomorrow)) return 'Jutro';
    try {
      return DateFormat('d MMM yyyy', 'pl_PL').format(normalized);
    } catch (_) {
      return '${normalized.day.toString().padLeft(2, '0')}.${normalized.month.toString().padLeft(2, '0')}.${normalized.year}';
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickCustomDate() async {
    final today = SchoolTask.todayStart;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedTitle = _titleController.text.trim();
    if (trimmedTitle.isEmpty) return;

    final trimmedDesc = _descriptionController.text.trim();
    final trimmedSubject = _subjectController.text.trim();

    setState(() => _isSaving = true);

    final user = ref.read(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final familyId = user?.familyId ?? 'jankiewicz_family';
    final actorRole = isStudent ? 'student' : 'parent';
    final actorName = isStudent
        ? 'Oskar'
        : ((user?.displayName.trim().isNotEmpty ?? false)
            ? user!.displayName.trim()
            : 'Tata');

    final repo = ref.read(tasksRepositoryProvider);

    try {
      if (_isEditing) {
        final existing = widget.existingTask!;
        final updated = existing.copyWith(
          title: trimmedTitle,
          description: trimmedDesc.isNotEmpty ? trimmedDesc : null,
          clearDescription: trimmedDesc.isEmpty,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          priority: _priority,
          assignedTo: _assignedTo,
          subject: trimmedSubject.isNotEmpty ? trimmedSubject : null,
          clearSubject: trimmedSubject.isEmpty,
        );
        await repo.updateTask(familyId, updated);
      } else {
        await repo.addTask(
          familyId: familyId,
          title: trimmedTitle,
          description: trimmedDesc.isNotEmpty ? trimmedDesc : null,
          dueDate: _dueDate,
          priority: _priority,
          assignedTo: _assignedTo,
          subject: trimmedSubject.isNotEmpty ? trimmedSubject : null,
          createdByRole: actorRole,
          createdByName: actorName,
          source: widget.initialSource ?? TaskSource.manual,
          sourceId: widget.initialSourceId,
          metadata: widget.initialMetadata,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się zapisać zadania: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmAndDelete(SchoolTask task, bool isStudent) async {
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
          style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
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
    final deleted = await ref.read(tasksRepositoryProvider).deleteTask(
          familyId,
          task,
          isStudent: isStudent,
        );

    if (mounted) {
      if (deleted) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Zadanie zlecone przez Rodzica — brak możliwości usunięcia.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final existing = widget.existingTask;
    final canDelete =
        existing != null && existing.canBeDeletedBy(isStudent: isStudent);
    final isLockedForStudent =
        existing != null && !existing.canBeDeletedBy(isStudent: isStudent);

    final today = SchoolTask.todayStart;
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit_note_rounded : Icons.add_task,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEditing ? 'Edytuj zadanie' : 'Nowe zadanie',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Parent lock banner (D-03)
            if (isLockedForStudent) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_person_outlined,
                      size: 18,
                      color: AppColors.tertiary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Zadanie zlecone przez Rodzica — konto ucznia może oznaczyć zadanie jako wykonane lub dopisać notatkę, ale nie może go usunąć.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onTertiaryFixed,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Title field
            const Text(
              'Tytuł zadania *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Np. Powtórzyć dział z biologii przed sprawdzianem',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Wpisz tytuł zadania';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description / note field
            const Text(
              'Opis lub notatka (opcjonalnie)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurface,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText:
                    'Dodatkowe szczegóły, strony z podręcznika lub notatka ucznia...',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Role Assignment (D-01)
            const Text(
              'Dla kogo (Przypisanie roli)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAssigneeChip(
                  assignee: TaskAssignee.student,
                  label: 'Dla Oskara',
                  icon: Icons.school_outlined,
                  bgColor: AppColors.primaryFixed,
                  fgColor: AppColors.onPrimaryFixed,
                ),
                _buildAssigneeChip(
                  assignee: TaskAssignee.parent,
                  label: 'Dla Rodzica',
                  icon: Icons.verified_user_outlined,
                  bgColor: AppColors.tertiaryFixed,
                  fgColor: AppColors.onTertiaryFixed,
                ),
                _buildAssigneeChip(
                  assignee: TaskAssignee.shared,
                  label: 'Wspólne',
                  icon: Icons.people_outline,
                  bgColor: AppColors.secondaryContainer,
                  fgColor: AppColors.onSecondaryFixedVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Priority (D-02)
            const Text(
              'Priorytet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPriorityChip(
                  priority: TaskPriority.high,
                  label: '🔴 Wysoki',
                  bgColor: AppColors.errorContainer,
                  fgColor: AppColors.onErrorContainer,
                ),
                _buildPriorityChip(
                  priority: TaskPriority.medium,
                  label: '🔵 Normalny',
                  bgColor: AppColors.primaryFixed,
                  fgColor: AppColors.onPrimaryFixedVariant,
                ),
                _buildPriorityChip(
                  priority: TaskPriority.low,
                  label: '⚪ Niski',
                  bgColor: AppColors.surfaceContainerLow,
                  fgColor: AppColors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Due Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Termin wykonania',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDateLabel(_dueDate),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickDateChip('Dzisiaj', today),
                _buildQuickDateChip('Jutro', tomorrow),
                _buildQuickDateChip('Za tydzień', nextWeek),
                _buildQuickDateChip('Bez terminu', null),
                ActionChip(
                  avatar: const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Kalendarz...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  backgroundColor: AppColors.surfaceContainerLow,
                  side: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                  onPressed: _pickCustomDate,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject / Category (D-02)
            const Text(
              'Przedmiot lub kategoria',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _subjectController,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Wybierz z listy poniżej lub wpisz własny...',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _presetSubjects.map((subject) {
                final isSelected =
                    _subjectController.text.trim().toLowerCase() ==
                        subject.toLowerCase();
                return ChoiceChip(
                  label: Text(
                    subject,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceContainerLow,
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        _subjectController.clear();
                      } else {
                        _subjectController.text = subject;
                      }
                    });
                  },
                );
              }).toList(),
            ),

            // Edit mode attribution footer (D-01)
            if (existing != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_edu_outlined,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        existing.attributionLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (canDelete)
                  TextButton.icon(
                    onPressed: () => _confirmAndDelete(existing, isStudent),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    label: const Text(
                      'Usuń zadanie',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Anuluj'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _handleSubmit,
                      icon: Icon(
                        _isEditing ? Icons.save_outlined : Icons.add_task,
                        size: 18,
                      ),
                      label: Text(
                        _isEditing ? 'Zapisz zmiany' : 'Dodaj zadanie',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssigneeChip({
    required TaskAssignee assignee,
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
  }) {
    final isSelected = _assignedTo == assignee;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? AppColors.onPrimary : fgColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.onPrimary : fgColor,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: bgColor,
      showCheckmark: false,
      onSelected: (_) => setState(() => _assignedTo = assignee),
    );
  }

  Widget _buildPriorityChip({
    required TaskPriority priority,
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    final isSelected = _priority == priority;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.onPrimary : fgColor,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: bgColor,
      showCheckmark: false,
      onSelected: (_) => setState(() => _priority = priority),
    );
  }

  Widget _buildQuickDateChip(String label, DateTime? targetDate) {
    final isSelected = _isSameDay(_dueDate, targetDate);
    return ChoiceChip(
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
      backgroundColor: AppColors.surfaceContainerLow,
      showCheckmark: false,
      onSelected: (_) => setState(() => _dueDate = targetDate),
    );
  }
}
