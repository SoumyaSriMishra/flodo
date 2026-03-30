import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../screens/task_form_screen.dart';
import '../utils/slide_route.dart';
import 'highlighted_text.dart';
import '../screens/task_detail_screen.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.isBlocked,
    required this.blockerTitle,
    this.highlightQuery = '',
    this.showDragHandle = false,
    this.dragIndex = 0,
  });

  final Task task;
  final bool isBlocked;
  final String? blockerTitle;
  final String highlightQuery;
  final bool showDragHandle;
  final int dragIndex;

  @override
  Widget build(BuildContext context) {
    final isOverdue = DateUtilsX.isOverdue(task.dueDate, task.status);

    final card = Slidable(
      key: ValueKey(task.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: AppTheme.cError,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _openEdit(context),
            backgroundColor: AppTheme.cPrimary,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => TaskDetailScreen(task: task),
              transitionsBuilder: (_, animation, __, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0), // slides in from the right
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
          if (context.mounted) {
            context.read<TaskProvider>().reload();
          }
        },
        child: AnimatedOpacity(
          opacity: isBlocked ? 0.45 : 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: _CardBody(
            task: task,
            isBlocked: isBlocked,
            blockerTitle: blockerTitle,
            isOverdue: isOverdue,
            highlightQuery: highlightQuery,
          ),
        ),
      ),
    );

    if (!showDragHandle) return card;

    return ReorderableDelayedDragStartListener(
      index: dragIndex,
      child: card,
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    await Navigator.push(context, slideUpRoute(TaskFormScreen(task: task)));
    if (context.mounted) {
      await context.read<TaskProvider>().reload();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cSurfaceElevated,
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.cError)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<TaskProvider>().deleteTask(task.id);
      if (context.mounted) {
        AppTheme.showSnackBar(context, 'Task deleted', isError: true);
      }
    }
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.task,
    required this.isBlocked,
    required this.blockerTitle,
    required this.isOverdue,
    required this.highlightQuery,
  });

  final Task task;
  final bool isBlocked;
  final String? blockerTitle;
  final bool isOverdue;
  final String highlightQuery;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isBlocked ? const Color(0xFF1A1218) : AppTheme.cSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked ? const Color(0xFF3A2030) : AppTheme.cBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: HighlightedText(
                  text: task.title,
                  query: highlightQuery,
                  baseStyle: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF0F0F5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(status: task.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.description.isEmpty ? 'Add details... (optional)' : task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.cTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isOverdue ? Icons.schedule_rounded : Icons.calendar_today_rounded,
                size: 16,
                color: isOverdue ? AppTheme.cError : AppTheme.cTextSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM d, yyyy').format(task.dueDate),
                style: TextStyle(
                  color: isOverdue ? AppTheme.cError : AppTheme.cTextSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (isOverdue) ...[
                const SizedBox(width: 8),
                const _OverdueBadge(),
              ],
              const Spacer(),
              if (task.isRecurring)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2A3A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1A5070), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.repeat_rounded, size: 11, color: Color(0xFF3B9FE8)),
                      const SizedBox(width: 4),
                      Text(
                        task.recurrenceInterval ?? 'Recurring',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B9FE8),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (isBlocked) ...[
            const SizedBox(height: 8),
            const Divider(color: AppTheme.cBorder, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.lock_rounded, size: 14, color: AppTheme.cError),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Blocked by: ${blockerTitle ?? 'Unknown'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.cError, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE05C6A).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE05C6A).withValues(alpha: 0.4)),
      ),
      child: const Text(
        'Overdue',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.cError),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'Done' => (const Color(0xFF102A20), AppTheme.cSuccess),
      'In Progress' => (const Color(0xFF2A2010), AppTheme.cWarning),
      _ => (const Color(0xFF252530), AppTheme.cTextSecondary),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
