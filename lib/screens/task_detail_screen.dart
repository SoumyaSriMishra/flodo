import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final isBlocked = provider.isBlocked(task);
    final blockerTitle = isBlocked
        ? provider.getTaskById(task.blockedById!)?.title
        : null;
    final isOverdue = task.dueDate.isBefore(DateTime.now()) &&
        task.status != 'Done';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      // ── App Bar ──────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF3B9FE8), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Task Detail'),
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        actions: [
          // Edit button in top-right
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _openEdit(context),
              icon: const Icon(Icons.edit_rounded,
                  size: 16, color: Color(0xFF3B9FE8)),
              label: Text(
                'Edit',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF3B9FE8),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Body ─────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Status badge ──────────────────────────────────
            _StatusBadge(status: task.status),
            const SizedBox(height: 20),

            // ── Title in BLUE ─────────────────────────────────
            Text(
              task.title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3B9FE8), // blue as requested
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),

            // ── Divider ───────────────────────────────────────
            const Divider(color: Color(0xFF2A2A30), height: 1),
            const SizedBox(height: 20),

            // ── Description ───────────────────────────────────
            if (task.description.isNotEmpty) ...[
              const _SectionLabel(label: 'Description'),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: const Color(0xFFCCCCD8), // white-ish per theme
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Due Date ──────────────────────────────────────
            const _SectionLabel(label: 'Due Date'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: isOverdue
                      ? const Color(0xFFE05C6A)
                      : const Color(0xFF3B9FE8),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMMM d, yyyy').format(task.dueDate),
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isOverdue
                        ? const Color(0xFFE05C6A)
                        : const Color(0xFFF0F0F5),
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1018),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFE05C6A), width: 1),
                    ),
                    child: Text(
                      'Overdue',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE05C6A),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // ── Blocked By ────────────────────────────────────
            if (task.blockedById != null) ...[
              const _SectionLabel(label: 'Blocked By'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1218),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isBlocked
                          ? const Color(0xFF3A2030)
                          : const Color(0xFF2A2A30)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isBlocked
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      size: 16,
                      color: isBlocked
                          ? const Color(0xFFE05C6A)
                          : const Color(0xFF3BCFA8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isBlocked
                            ? 'Blocked by: ${blockerTitle ?? 'Unknown task'}'
                            : 'Was blocked by: ${blockerTitle ?? 'a completed task'}',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: isBlocked
                              ? const Color(0xFFE05C6A)
                              : const Color(0xFF3BCFA8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Recurring ─────────────────────────────────────
            if (task.isRecurring) ...[
              const _SectionLabel(label: 'Recurrence'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2A3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF1A5070), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat_rounded,
                        size: 16, color: Color(0xFF3B9FE8)),
                    const SizedBox(width: 10),
                    Text(
                      'Repeats ${task.recurrenceInterval ?? 'regularly'}',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: const Color(0xFF3B9FE8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Divider(color: Color(0xFF2A2A30), height: 1),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => TaskFormScreen(task: task),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
    // Reload after edit
    if (context.mounted) {
      context.read<TaskProvider>().reload();
    }
  }
}

// ── Helper Widgets ────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF4A4A5A),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _bgColor {
    switch (status) {
      case 'Done': return const Color(0xFF102A20);
      case 'In Progress': return const Color(0xFF2A2010);
      default: return const Color(0xFF252530);
    }
  }

  Color get _textColor {
    switch (status) {
      case 'Done': return const Color(0xFF3BCFA8);
      case 'In Progress': return const Color(0xFFE8A83B);
      default: return const Color(0xFF7A7A8C);
    }
  }

  IconData get _icon {
    switch (status) {
      case 'Done': return Icons.check_circle_rounded;
      case 'In Progress': return Icons.timelapse_rounded;
      default: return Icons.radio_button_unchecked_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _textColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}
