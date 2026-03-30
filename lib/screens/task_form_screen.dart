import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../models/task.dart';
import '../providers/draft_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  bool get isEditMode => task != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  Timer? _debounce;

  DateTime? _selectedDate;
  String _selectedStatus = 'To-Do';
  String? _selectedBlockedById;
  bool _dateError = false;
  bool _isSaving = false;
  bool _isRecurring = false;
  String _recurrenceInterval = 'Daily';

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description;
      _selectedDate = widget.task!.dueDate;
      _selectedStatus = widget.task!.status;
      _selectedBlockedById = widget.task!.blockedById;
      _isRecurring = widget.task!.isRecurring;
      _recurrenceInterval = widget.task!.recurrenceInterval ?? 'Daily';
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final draft = context.read<DraftProvider>();
        draft.loadDraft().then((_) {
          if (!mounted) return;
          setState(() {
            _titleController.text = draft.draftTitle;
            _descController.text = draft.draftDescription;
            _selectedDate = draft.draftDueDate;
            _selectedStatus = draft.draftStatus;
            _selectedBlockedById = draft.draftBlockedById;
            _isRecurring = draft.draftIsRecurring;
            _recurrenceInterval = draft.draftRecurrenceInterval ?? 'Daily';
          });
        });
      });
    }

    if (widget.task == null) {
      _titleController.addListener(_onFieldChanged);
      _descController.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.task == null) {
      _titleController.removeListener(_onFieldChanged);
      _descController.removeListener(_onFieldChanged);
    }
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<DraftProvider>().saveDraft(
            title: _titleController.text,
            description: _descController.text,
            dueDate: _selectedDate,
            status: _selectedStatus,
            blockedById: _selectedBlockedById,
            isRecurring: _isRecurring,
            recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = context.read<TaskProvider>().allTasks;
    final otherTasks = allTasks.where((t) => t.id != widget.task?.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        actions: [
          if (widget.task != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.cError),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormSection(
                  label: 'Title',
                  field: TextFormField(
                    controller: _titleController,
                    maxLength: 80,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => Text(
                      '$currentLength/$maxLength',
                      style: const TextStyle(fontSize: 11, color: AppTheme.cTextMuted),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    decoration: const InputDecoration(hintText: 'What needs to be done?'),
                  ),
                ),
                const SizedBox(height: 12),
                _FormSection(
                  label: 'Description',
                  field: TextFormField(
                    controller: _descController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(hintText: 'Add details... (optional)'),
                  ),
                ),
                const SizedBox(height: 12),
                _FormSection(
                  label: 'Due Date',
                  field: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cSurfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _dateError ? AppTheme.cError : AppTheme.cBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.cPrimary),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate != null ? DateFormat('MMM d, yyyy').format(_selectedDate!) : 'Select a date',
                            style: TextStyle(
                              color: _selectedDate != null ? AppTheme.cTextPrimary : AppTheme.cTextMuted,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_dateError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text('Please select a due date', style: TextStyle(color: AppTheme.cError, fontSize: 12)),
                  ),
                const SizedBox(height: 12),
                _FormSection(
                  label: 'Status',
                  field: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(),
                    dropdownColor: AppTheme.cSurfaceElevated,
                    items: const ['To-Do', 'In Progress', 'Done'].map((s) {
                      final dot = s == 'Done'
                          ? AppTheme.cSuccess
                          : s == 'In Progress'
                              ? AppTheme.cWarning
                              : AppTheme.cTextMuted;
                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: dot)),
                            const SizedBox(width: 10),
                            Text(s),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() => _selectedStatus = v!);
                      if (widget.task == null) _onFieldChanged();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _FormSection(
                  label: 'Blocked By',
                  field: DropdownButtonFormField<String?>(
                    initialValue: _selectedBlockedById,
                    decoration: const InputDecoration(
                      helperText: 'Select a task that must be completed first',
                      helperStyle: TextStyle(fontSize: 11, color: AppTheme.cTextMuted),
                    ),
                    dropdownColor: AppTheme.cSurfaceElevated,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None — not blocked'),
                      ),
                      ...otherTasks.map((t) => DropdownMenuItem<String?>(
                            value: t.id,
                            child: Text(t.title, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedBlockedById = v);
                      if (widget.task == null) _onFieldChanged();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _FormSection(
                  label: 'Recurring',
                  field: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A30)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.repeat_rounded, size: 20, color: Color(0xFF3B9FE8)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recurring Task',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFF0F0F5),
                                      ),
                                    ),
                                    Text(
                                      'Auto-schedule the next occurrence when done',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: const Color(0xFF7A7A8C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _isRecurring,
                                activeTrackColor: const Color(0xFF3B9FE8).withValues(alpha: 0.5),
                                activeThumbColor: const Color(0xFFFFFFFF),
                                onChanged: (val) {
                                  setState(() => _isRecurring = val);
                                  if (widget.task == null) _onFieldChanged();
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_isRecurring) ...[
                          const Divider(height: 1, color: Color(0xFF2A2A30)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const SizedBox(width: 32),
                                const Text(
                                  'Repeat every:',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF7A7A8C)),
                                ),
                                const SizedBox(width: 16),
                                _IntervalChip(
                                  label: 'Daily',
                                  icon: Icons.wb_sunny_rounded,
                                  isSelected: _recurrenceInterval == 'Daily',
                                  onTap: () {
                                    setState(() => _recurrenceInterval = 'Daily');
                                    if (widget.task == null) _onFieldChanged();
                                  },
                                ),
                                const SizedBox(width: 8),
                                _IntervalChip(
                                  label: 'Weekly',
                                  icon: Icons.calendar_view_week_rounded,
                                  isSelected: _recurrenceInterval == 'Weekly',
                                  onTap: () {
                                    setState(() => _recurrenceInterval = 'Weekly');
                                    if (widget.task == null) _onFieldChanged();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: _isSaving
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF3B9FE8), Color(0xFF1A7FD4)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: _isSaving ? const Color(0xFF2A3A4A) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isSaving ? null : _saveTask,
                      child: Center(
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Saving...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                widget.task == null ? 'Save Task' : 'Update Task',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.cPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = false;
      });
      if (widget.task == null) _onFieldChanged();
    }
  }

  Future<void> _saveTask() async {
    final isFormValid = _formKey.currentState!.validate();
    if (_selectedDate == null) setState(() => _dateError = true);
    if (!isFormValid || _selectedDate == null) return;

    setState(() => _isSaving = true);
    final provider = context.read<TaskProvider>();

    if (widget.task == null) {
      final t = Task(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        dueDate: _selectedDate!,
        status: _selectedStatus,
        blockedById: _selectedBlockedById,
        isRecurring: _isRecurring,
        recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
      );
      await provider.addTask(t);
      if (mounted) await context.read<DraftProvider>().clearDraft();

      var spawned = false;
      if (_selectedStatus == 'Done' && t.isRecurring && t.recurrenceInterval != null) {
        spawned = await provider.addRecurringFollowUp(t);
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      if (spawned) {
        AppTheme.showSnackBar(
          context,
          '↻ New recurring task scheduled',
          duration: const Duration(seconds: 3),
        );
      } else {
        AppTheme.showSnackBar(context, 'Task saved!');
      }
      Navigator.pop(context);
    } else {
      widget.task!
        ..title = _titleController.text.trim()
        ..description = _descController.text.trim()
        ..dueDate = _selectedDate!
        ..status = _selectedStatus
        ..blockedById = _selectedBlockedById
        ..isRecurring = _isRecurring
        ..recurrenceInterval = _isRecurring ? _recurrenceInterval : null;

      var spawned = false;
      if (_selectedStatus == 'Done') {
        spawned = await provider.markDoneAndRecur(widget.task!);
      } else {
        await provider.updateTask(widget.task!);
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      if (spawned) {
        AppTheme.showSnackBar(
          context,
          '↻ New recurring task scheduled',
          duration: const Duration(seconds: 3),
        );
      } else {
        AppTheme.showSnackBar(context, 'Task updated!');
      }
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
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
    if (confirmed == true && mounted) {
      await context.read<TaskProvider>().deleteTask(widget.task!.id);
      if (!mounted) return;
      AppTheme.showSnackBar(context, 'Task deleted', isError: true);
      Navigator.pop(context);
    }
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.label, required this.field});

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.cTextSecondary),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}

class _IntervalChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntervalChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B9FE8) : const Color(0xFF161618),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B9FE8) : const Color(0xFF2A2A30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF7A7A8C)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF7A7A8C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
