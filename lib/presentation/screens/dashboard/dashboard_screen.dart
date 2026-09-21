import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "../../../core/theme/app_colors.dart";
import "../../../domain/models/lesson_slot.dart";
import "../../../domain/models/grade.dart";
import "../../../domain/models/message_thread.dart";
import "../../../domain/models/attendance_record.dart";
import "../../../domain/models/teacher_contact.dart";
import "../../../domain/models/student_profile.dart";
import "../../providers/school_providers.dart";
import "../../providers/sync_provider.dart";
import "../grades/grade_details_modal.dart";
import "../attendance/justification_modal.dart";
import "../messages/new_message_screen.dart";
import "../messages/message_thread_screen.dart";
import "../../widgets/modals/librus_query_log_modal.dart";
import "package:go_router/go_router.dart";

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedMessageTab = 0; // 0: Wszystkie, 1: Nieprzeczytane, 2: Ogłoszenia

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return _buildDesktopDashboard(context);
        }
        return _buildMobileDashboard(context);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP DASHBOARD (>= 1024px)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopDashboard(BuildContext context) {
    final studentAsync = ref.watch(studentProfileProvider);
    final scheduleAsync = ref.watch(todayScheduleProvider);
    final recentGradesAsync = ref.watch(recentGradesProvider);
    final messagesAsync = ref.watch(messagesProvider);
    final attendanceAsync = ref.watch(attendanceProvider);
    final teachersAsync = ref.watch(teachersProvider);
    final examAsync = ref.watch(upcomingExamProvider);

    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final rawDate = DateFormat("EEEE, d MMMM y", "pl_PL").format(now);
    final formattedDate = rawDate.isNotEmpty
        ? "${rawDate[0].toUpperCase()}${rawDate.substring(1)}"
        : rawDate;

    final lessons = scheduleAsync.value ?? [];
    final firstLesson = lessons.isNotEmpty ? lessons.first : null;
    final lastLesson = lessons.isNotEmpty ? lessons.last : null;
    final cancelledLessons = lessons.where((l) => l.status == LessonStatus.canceled).toList();
    final effectiveCount = lessons.length - cancelledLessons.length;
    final startTimeStr = firstLesson != null ? firstLesson.startTime : "08:00";
    final endTimeStr = lastLesson != null ? lastLesson.endTime : "14:25";

    final student = studentAsync.value;
    final grades = recentGradesAsync.value ?? [];
    final allMessages = messagesAsync.value ?? [];
    final unreadMessages = allMessages.where((m) => m.isUnread).toList();
    final announcementMessages = allMessages.where((m) {
      final s = m.subject.toLowerCase();
      final r = m.senderRole.toLowerCase();
      return s.contains("ogłoszen") || s.contains("komunikat") || r.contains("dyrekcj");
    }).toList();

    final unexcusedRecords = (attendanceAsync.value ?? [])
        .where((r) => r.type == AttendanceType.absent && r.justificationStatus == JustificationStatus.none)
        .toList();

    // Filtered messages by tab
    final displayedMessages = _selectedMessageTab == 0
        ? allMessages
        : (_selectedMessageTab == 1 ? unreadMessages : announcementMessages);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncProvider.notifier).syncNow();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Welcome & Daily Real-Time Banner
                  _buildDesktopWelcomeBanner(
                    context,
                    student: student,
                    formattedDate: formattedDate,
                    startTimeStr: startTimeStr,
                    endTimeStr: endTimeStr,
                    effectiveCount: effectiveCount,
                    cancelledLessons: cancelledLessons,
                    isWeekend: isWeekend,
                    hasLessons: lessons.isNotEmpty,
                  ),

                  const SizedBox(height: 24),

                  // 2. Main 3-Column Bento Grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column 1: Harmonogram na dziś (~35% flex: 4)
                      Expanded(
                        flex: 4,
                        child: _buildDesktopScheduleColumn(
                          context,
                          lessons: lessons,
                          now: now,
                          exam: examAsync.value,
                          isWeekend: isWeekend,
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Column 2: Wiadomości i Komunikaty (~40% flex: 5)
                      Expanded(
                        flex: 5,
                        child: _buildDesktopMessagesColumn(
                          context,
                          displayedMessages: displayedMessages,
                          unreadCount: unreadMessages.length,
                          totalCount: allMessages.length,
                          announcementCount: announcementMessages.length,
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Column 3: Ostatnie oceny & Frekwencja & Skróty (~25% flex: 3)
                      Expanded(
                        flex: 3,
                        child: _buildDesktopMetricsColumn(
                          context,
                          student: student,
                          grades: grades,
                          unexcusedRecords: unexcusedRecords,
                          teachers: teachersAsync.value ?? [],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Top Welcome Banner ---
  Widget _buildDesktopWelcomeBanner(
    BuildContext context, {
    required StudentProfile? student,
    required String formattedDate,
    required String startTimeStr,
    required String endTimeStr,
    required int effectiveCount,
    required List<LessonSlot> cancelledLessons,
    required bool isWeekend,
    required bool hasLessons,
  }) {
    final firstName = (student != null && student.name.isNotEmpty)
        ? student.name.split(" ").first
        : "Oskar";

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      "Dzień dobry, $firstName! 👋",
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                    ),
                    // Lucky number pill (single place, clean number)
                    Builder(
                      builder: (context) {
                        final luckyNumber = student?.luckyNumber ?? 0;
                        if (isWeekend) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("🍀", style: TextStyle(fontSize: 13)),
                                SizedBox(width: 6),
                                Text(
                                  "Brak losowania w weekend",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (luckyNumber <= 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("🍀", style: TextStyle(fontSize: 13)),
                                SizedBox(width: 6),
                                Text(
                                  "Brak losowania dzisiaj",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("🍀", style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                    const TextSpan(text: "Szczęśliwy numerek: "),
                                    TextSpan(
                                      text: "$luckyNumber",
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Semester / Week pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${student?.currentWeek ?? "Tydzień A"} • Semestr 1",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // State pill (Librus status & Access log trigger)
                    Tooltip(
                      message: "Status systemu: Stan normalny • Kliknij, aby zobaczyć dziennik zapytań Librus (Access Log)",
                      child: InkWell(
                        onTap: () => LibrusQueryLogModal.show(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.onSecondaryContainer,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Stan normalny",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Text("•", style: TextStyle(color: AppColors.outlineVariant)),
                    if (isWeekend || !hasLessons) ...[
                      Text(
                        isWeekend
                            ? "Weekend • Dzień wolny od zajęć lekcyjnych 🎉"
                            : "Dzień wolny od zajęć lekcyjnych 🎉",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      Text(
                        "Początek lekcji: $startTimeStr",
                        style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                      if (cancelledLessons.isNotEmpty) ...[
                        Text(
                          "(Lekcja ${cancelledLessons.first.lessonNumber} odwołana - ${cancelledLessons.first.subjectName})",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const Text("•", style: TextStyle(color: AppColors.outlineVariant)),
                      Text(
                        "Koniec: $endTimeStr ($effectiveCount lekcje efektywne)",
                        style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Column 1: Harmonogram dnia ---
  Widget _buildDesktopScheduleColumn(
    BuildContext context, {
    required List<LessonSlot> lessons,
    required DateTime now,
    UpcomingEvent? exam,
    required bool isWeekend,
  }) {
    int completedCount = 0;
    for (final l in lessons) {
      if (l.status == LessonStatus.canceled) {
        completedCount++;
        continue;
      }
      try {
        final endParts = l.endTime.split(":").map(int.parse).toList();
        final end = DateTime(now.year, now.month, now.day, endParts[0], endParts[1]);
        if (now.isAfter(end)) completedCount++;
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Harmonogram Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Harmonogram na dziś",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lessons.isEmpty
                          ? (isWeekend ? "Weekend" : "Dzień wolny")
                          : "$completedCount / ${lessons.length} zrealizowane",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (lessons.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.weekend_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isWeekend
                            ? "Brak lekcji na dzisiaj • Weekend 🎉"
                            : "Brak lekcji na dzisiaj • Dzień wolny 🎉",
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isWeekend
                            ? "Dziś nie masz zajęć lekcyjnych. Odpocznij i nabierz sił na nadchodzący tydzień nauki!"
                            : "Ciesz się wolnym czasem lub powtórz materiał na nadchodzące lekcje.",
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...lessons.map((lesson) => _buildDesktopLessonItem(context, lesson, now)),

              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/plan-lekcji');
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text("Pełny plan lekcji na cały tydzień"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLow,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        if (exam != null) ...[
          const SizedBox(height: 20),

          // Nadchodzący Sprawdzian Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 18, color: AppColors.tertiary),
                        SizedBox(width: 8),
                        Text(
                          "Nadchodzący sprawdzian",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryFixed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exam.daysRemaining == 0
                            ? "Dzisiaj"
                            : exam.daysRemaining == 1
                                ? "Jutro"
                                : "Za ${exam.daysRemaining} dni",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onTertiaryFixed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${exam.subject} (${exam.type.toLowerCase()})",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat("d MMMM", "pl_PL").format(exam.date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Zakres: ${exam.title}",
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      if (exam.room.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          exam.room,
                          style: const TextStyle(fontSize: 11, color: AppColors.outline),
                        ),
                      ],
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          final dateStr = DateFormat('yyyy-MM-dd').format(exam.date);
                          context.go('/plan-lekcji?data=$dateStr');
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              "Zobacz w terminarzu",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopLessonItem(BuildContext context, LessonSlot lesson, DateTime now) {
    bool isInProgress = lesson.status == LessonStatus.inProgress;
    double progress = lesson.progressFraction ?? 0.0;
    int remainingMinutes = 0;

    if (lesson.status != LessonStatus.canceled) {
      try {
        final sParts = lesson.startTime.split(":").map(int.parse).toList();
        final eParts = lesson.endTime.split(":").map(int.parse).toList();
        final start = DateTime(now.year, now.month, now.day, sParts[0], sParts[1]);
        final end = DateTime(now.year, now.month, now.day, eParts[0], eParts[1]);

        if (now.isAfter(start) && now.isBefore(end)) {
          isInProgress = true;
          final totalSec = end.difference(start).inSeconds;
          final elapsedSec = now.difference(start).inSeconds;
          progress = (elapsedSec / totalSec).clamp(0.0, 1.0);
          remainingMinutes = end.difference(now).inMinutes;
        }
      } catch (_) {}
    }

    Color stripeColor = AppColors.outlineVariant;
    if (lesson.status == LessonStatus.canceled) {
      stripeColor = AppColors.error;
    } else if (isInProgress) {
      stripeColor = AppColors.primary;
    } else if (lesson.status == LessonStatus.substituted) {
      stripeColor = AppColors.tertiary;
    } else {
      stripeColor = AppColors.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInProgress
            ? AppColors.primaryFixed.withValues(alpha: 0.25)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4px vertical stripe
          Container(
            width: 4,
            height: isInProgress ? 65 : 44,
            decoration: BoxDecoration(
              color: stripeColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${lesson.startTime} - ${lesson.endTime}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isInProgress ? FontWeight.bold : FontWeight.w500,
                        color: isInProgress ? AppColors.primary : AppColors.onSurfaceVariant,
                        decoration: lesson.status == LessonStatus.canceled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (lesson.status == LessonStatus.canceled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "ODWOŁANE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      )
                    else if (isInProgress)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "W TRAKCIE",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (lesson.status == LessonStatus.substituted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "ZASTĘPSTWO",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onTertiaryFixed,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "PLANOWO",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${lesson.lessonNumber}. ${lesson.subjectName}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isInProgress ? AppColors.primary : AppColors.onSurface,
                        decoration: lesson.status == LessonStatus.canceled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      lesson.room.isNotEmpty ? "Sala ${lesson.room}" : "",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                if (lesson.status == LessonStatus.canceled) ...[
                  const SizedBox(height: 2),
                  Text(
                    lesson.statusNote ?? "Lekcja odwołana",
                    style: const TextStyle(fontSize: 11, color: AppColors.error),
                  ),
                ],

                if (lesson.status == LessonStatus.substituted && lesson.substituteTeacher != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Zamiast ${lesson.teacher} prowadzi ${lesson.substituteTeacher}",
                    style: const TextStyle(fontSize: 11, color: AppColors.tertiary),
                  ),
                ],

                if (isInProgress) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lesson.teacher,
                        style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                      ),
                      Text(
                        "Zostało $remainingMinutes min",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Column 2: Wiadomości i Komunikaty ---
  Widget _buildDesktopMessagesColumn(
    BuildContext context, {
    required List<MessageThread> displayedMessages,
    required int unreadCount,
    required int totalCount,
    required int announcementCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Wiadomości i Komunikaty",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        "Skrzynka odbiorcza EduSync",
                        style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  context.go('/wiadomosci');
                },
                child: const Row(
                  children: [
                    Text(
                      "Otwórz skrzynkę",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter Tab Pills
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildFilterPill(
                  index: 0,
                  label: "Wszystkie",
                  isSelected: _selectedMessageTab == 0,
                ),
                _buildFilterPill(
                  index: 1,
                  label: "Nieprzeczytane ($unreadCount)",
                  isSelected: _selectedMessageTab == 1,
                ),
                _buildFilterPill(
                  index: 2,
                  label: "Ogłoszenia ($announcementCount)",
                  isSelected: _selectedMessageTab == 2,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Messages List
          if (displayedMessages.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text(
                _selectedMessageTab == 1
                    ? "Wszystkie wiadomości zostały przeczytane"
                    : (_selectedMessageTab == 2
                        ? "Brak ogłoszeń szkolnych"
                        : "Brak wiadomości w skrzynce"),
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            )
          else
            ...displayedMessages.take(3).map((msg) => _buildDesktopMessageArticle(context, msg)),

          const SizedBox(height: 12),

          // School Bulletin Highlight Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "14 Listopada: Dzień Wolny",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        "Konferencja metodyczna rady pedagogicznej",
                        style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    context.go('/plan-lekcji');
                  },
                  icon: const Icon(Icons.event, size: 14),
                  label: const Text("Szczegóły"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required int index,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMessageTab = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopMessageArticle(BuildContext context, MessageThread msg) {
    final isUrgent = msg.subject.toLowerCase().contains("pilne") || msg.isUnread;
    final isDirector = msg.senderRole.toLowerCase().contains("dyrekcj");
    final timeStr = DateFormat("d MMM, HH:mm", "pl_PL").format(msg.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (msg.isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    msg.senderName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (msg.senderRole.isNotEmpty) ...[
                    Text(
                      " • ${msg.senderRole}",
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "PILNE",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                    )
                  else if (isDirector)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "DYREKCJA",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimaryFixed,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            msg.subject,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            msg.preview,
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (msg.attachments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text("Załącznik PDF", style: TextStyle(fontSize: 11)),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      context.go('/wiadomosci/${msg.id}', extra: msg);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    child: const Text("Odpowiedz"),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: "Szczegóły wątku",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessageThreadScreen(thread: msg),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chevron_right, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Column 3: Oceny, Frekwencja & Szybkie Akcje ---
  Widget _buildDesktopMetricsColumn(
    BuildContext context, {
    required StudentProfile? student,
    required List<Grade> grades,
    required List<AttendanceRecord> unexcusedRecords,
    required List<TeacherContact> teachers,
  }) {
    final attendancePct = student?.attendancePercentage ?? 98.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Ostatnie oceny Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.military_tech_outlined, size: 20, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Text(
                    "Ostatnie oceny",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Kolorowy pasek średniej ważonej
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.6),
                      AppColors.secondaryContainer.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.trending_up, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ŚREDNIA WAŻONA",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  (student?.overallAverage ?? 5.0).toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "Top 5%",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      student != null && student.overallAverage >= 4.75
                          ? "Wyróżnienie 🏅"
                          : "Bardzo dobry wynik",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              if (grades.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Brak najnowszych ocen", style: TextStyle(color: AppColors.outline)),
                )
              else
                ...grades.take(3).map((g) => _buildDesktopGradeRow(context, g)),

              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  context.go('/oceny');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Zobacz wszystkie oceny",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Frekwencja Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.fact_check_outlined, size: 20, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Text(
                        "Frekwencja",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${attendancePct.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Wymóg min. 50%",
                    style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                  Text(
                    "Cel roczny: 90% (Osiągnięty)",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 2-Color Attendance Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (attendancePct * 10).toInt(),
                        child: Container(color: AppColors.secondary),
                      ),
                      Expanded(
                        flex: ((100 - attendancePct) * 10).toInt(),
                        child: Container(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ),

              if (unexcusedRecords.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryFixed.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.tertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${unexcusedRecords.length} godz. do usprawiedliwienia",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onTertiaryFixed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final recordIds = unexcusedRecords.map((r) => r.id).toList();
                  JustificationModal.show(
                    context,
                    recordIds,
                    "Wizyta lekarska",
                    (reason, pin, selectedDate) async {
                      await ref.read(attendanceProvider.notifier).submitJustification(
                            recordIds,
                            reason,
                            date: selectedDate,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Wniosek o usprawiedliwienie został pomyślnie wysłany."),
                            backgroundColor: Color(0xFF006C4A),
                          ),
                        );
                      }
                    },
                  );
                },
                icon: const Icon(Icons.security, size: 16),
                label: const Text("Szybkie usprawiedliwienie (PIN)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Quick Action Widgets Mosaic
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _buildDesktopShortcutTile(
                icon: Icons.assignment_outlined,
                iconBg: AppColors.primaryFixed,
                iconColor: AppColors.primary,
                title: "Zadania domowe",
                subtitle: "Terminarz i sprawdziany",
                onTap: () {
                  context.go('/plan-lekcji');
                },
              ),
              const Divider(height: 12, color: AppColors.surfaceContainerHigh),
              _buildDesktopShortcutTile(
                icon: Icons.forum_outlined,
                iconBg: AppColors.secondaryContainer,
                iconColor: AppColors.secondary,
                title: "Kontakt z wychowawcą",
                subtitle: "Napisz nową wiadomość",
                onTap: () {
                  final educatorName = student?.educator ?? "Wychowawca";
                  final homeroomTeacher = teachers.firstWhere(
                    (t) => t.role.toLowerCase().contains("wychowawc") || t.subjectName.toLowerCase().contains("wychowawc") || t.id == 'educator',
                    orElse: () => teachers.isNotEmpty
                        ? teachers.first
                        : TeacherContact(
                            id: "educator",
                            name: educatorName,
                            subjectName: "Wychowawstwo",
                            role: "Wychowawca",
                            initials: educatorName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase(),
                          ),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewMessageScreen(initialRecipient: homeroomTeacher),
                    ),
                  );
                },
              ),
              const Divider(height: 12, color: AppColors.surfaceContainerHigh),
              _buildDesktopShortcutTile(
                icon: Icons.event_busy_outlined,
                iconBg: AppColors.surfaceContainerHigh,
                iconColor: AppColors.onSurface,
                title: "Zgłoś nieobecność",
                subtitle: "e-Usprawiedliwienie",
                onTap: () {
                  final recordIds = unexcusedRecords.map((r) => r.id).toList();
                  JustificationModal.show(
                    context,
                    recordIds,
                    "Wizyta lekarska",
                    (reason, pin, selectedDate) async {
                      await ref.read(attendanceProvider.notifier).submitJustification(
                            recordIds,
                            reason,
                            date: selectedDate,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Wniosek o usprawiedliwienie został pomyślnie wysłany."),
                            backgroundColor: Color(0xFF006C4A),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGradeRow(BuildContext context, Grade grade) {
    final dateStr = DateFormat("d MMM", "pl_PL").format(grade.date);

    return InkWell(
      onTap: () => GradeDetailsModal.show(context, grade),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                grade.rawValue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.subjectName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${grade.categoryName} • waga ${grade.weight}",
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopShortcutTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.outline),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE DASHBOARD (< 1024px) - PRESERVED ERGONOMIC MOBILE VIEW
  // ---------------------------------------------------------------------------
  Widget _buildMobileDashboard(BuildContext context) {
    final studentAsync = ref.watch(studentProfileProvider);
    final scheduleAsync = ref.watch(todayScheduleProvider);
    final recentGradesAsync = ref.watch(recentGradesProvider);
    final messagesAsync = ref.watch(messagesProvider);
    final unreadMessagesCount = ref.watch(unreadMessagesCountProvider);
    final syncState = ref.watch(syncProvider);

    final messages = messagesAsync.value ?? [];

    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final rawDate = DateFormat("EEEE, d MMMM", "pl_PL").format(now);
    final formattedDate = rawDate.isNotEmpty
        ? "${rawDate[0].toUpperCase()}${rawDate.substring(1)}"
        : rawDate;

    final lessons = scheduleAsync.value ?? [];
    final firstLesson = lessons.isNotEmpty ? lessons.first : null;
    final lastLesson = lessons.isNotEmpty ? lessons.last : null;
    final cancelledLessons = lessons.where((l) => l.status == LessonStatus.canceled).toList();
    final effectiveCount = lessons.length - cancelledLessons.length;
    final startTimeStr = firstLesson != null ? "Początek ${firstLesson.startTime}" : "Brak lekcji";
    final endTimeStr = lastLesson != null ? "Koniec zajęć: ${lastLesson.endTime} • $effectiveCount lekcji efektywnych" : "Dzień wolny";
    final statusNoteStr = lessons.isEmpty
        ? (isWeekend ? "Weekend" : "Dzień wolny")
        : (cancelledLessons.isNotEmpty
            ? "Lekcja ${cancelledLessons.first.lessonNumber} odwołana"
            : (lessons.any((l) => l.status == LessonStatus.substituted) ? "Zastępstwo w planie" : "Zgodnie z planem"));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncProvider.notifier).syncNow();
        },
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Top Academic Status Micro-Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    studentAsync.value?.currentWeek ?? "Tydzień B",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          "${studentAsync.value?.attendancePercentage ?? 98.6}% Frekw.",
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Sync Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: syncState.isDemoMode
                    ? const Color(0xFFFFFBEB)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: syncState.isDemoMode
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: syncState.isDemoMode
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : const Color(0xFF16A34A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      syncState.isDemoMode ? Icons.science_outlined : Icons.cloud_done_outlined,
                      size: 16,
                      color: syncState.isDemoMode ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              syncState.isDemoMode
                                  ? "Tryb demonstracyjny"
                                  : "Połączono z Librus Synergia",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: syncState.isDemoMode
                                    ? const Color(0xFF92400E)
                                    : const Color(0xFF166534),
                              ),
                            ),
                            if (syncState.connectedLogin != null && !syncState.isDemoMode) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "(${syncState.connectedLogin})",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF15803D),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          "Ostatnia synchronizacja: ${syncState.formattedLastSync}",
                          style: TextStyle(
                            fontSize: 11,
                            color: syncState.isDemoMode
                                ? const Color(0xFFB45309)
                                : const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: syncState.isSyncing
                        ? null
                        : () async {
                            await ref.read(syncProvider.notifier).syncNow();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Zsynchronizowano dane z Librusem"),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: syncState.isDemoMode
                            ? const Color(0xFFD97706).withValues(alpha: 0.1)
                            : const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: syncState.isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : Text(
                              "Odśwież",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: syncState.isDemoMode
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Daily Schedule Hero Card (Mobile)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "DZISIEJSZY PLAN ZAJĘĆ",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusNoteStr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (lessons.isEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.weekend_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isWeekend ? "Brak zajęć dzisiaj • Weekend 🎉" : "Brak lekcji na dzisiaj • Dzień wolny 🎉",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isWeekend
                                    ? "Odpocznij i zregeneruj siły przed nowym tygodniem."
                                    : "Ciesz się wolnym czasem lub powtórz materiał.",
                                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      startTimeStr,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      endTimeStr,
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    ...lessons.take(4).map(
                          (l) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  l.startTime,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l.subjectName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      decoration: l.status == LessonStatus.canceled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  l.room.isNotEmpty ? "Sala ${l.room}" : "",
                                  style: const TextStyle(fontSize: 11, color: AppColors.outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      context.go('/plan-lekcji');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Zobacz pełny plan lekcji",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Messages & Communications (Mobile)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: unreadMessagesCount > 0
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.outlineVariant.withValues(alpha: 0.3),
                  width: unreadMessagesCount > 0 ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "WIADOMOŚCI",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (unreadMessagesCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$unreadMessagesCount ${unreadMessagesCount == 1 ? 'nowa' : 'nowe'}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.go('/wiadomosci'),
                        child: const Text("Wszystkie →"),
                      ),
                    ],
                  ),
                  if (unreadMessagesCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_unread_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              unreadMessagesCount == 1
                                  ? "Masz 1 nową wiadomość"
                                  : "Masz $unreadMessagesCount nowe wiadomości",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (messages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          "Brak wiadomości w skrzynce",
                          style: TextStyle(fontSize: 12, color: AppColors.outline),
                        ),
                      ),
                    )
                  else
                    ...messages.take(3).map((msg) => _buildMobileMessageItem(context, msg)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Recent Grades (Mobile)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "OSTATNIE OCENY",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/oceny');
                        },
                        child: const Text("Wszystkie →"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if ((recentGradesAsync.value ?? []).isNotEmpty)
                    ...recentGradesAsync.value!.take(3).map(
                          (g) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.secondaryContainer,
                              child: Text(
                                g.rawValue,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSecondaryContainer,
                                ),
                              ),
                            ),
                            title: Text(g.subjectName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text("${g.categoryName} • waga ${g.weight}", style: const TextStyle(fontSize: 11)),
                            trailing: Text(DateFormat("d MMM", "pl_PL").format(g.date), style: const TextStyle(fontSize: 11, color: AppColors.outline)),
                            onTap: () => GradeDetailsModal.show(context, g),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMessageItem(BuildContext context, MessageThread msg) {
    final timeStr = DateFormat("d MMM, HH:mm", "pl_PL").format(msg.timestamp);

    return InkWell(
      onTap: () => context.go('/wiadomosci/${msg.id}', extra: msg),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: msg.isUnread
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: msg.isUnread
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.25))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: msg.isUnread
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceContainerHigh,
              child: Text(
                msg.senderInitials,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: msg.isUnread ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          msg.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: msg.isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: msg.isUnread ? AppColors.primary : AppColors.outline,
                          fontWeight: msg.isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.subject,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: msg.isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: msg.isUnread ? AppColors.primary : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (msg.preview.isNotEmpty && msg.preview != msg.subject) ...[
                    const SizedBox(height: 2),
                    Text(
                      msg.preview,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (msg.isUnread) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
