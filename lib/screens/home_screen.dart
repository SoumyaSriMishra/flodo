import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/search_row.dart';
import '../utils/slide_route.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  String _appliedQuery = '';
  String _statusFilter = 'All';
  bool _isSearchFocused = false;
  bool _isFabExtended = true;

  bool get _isFilterActive =>
      _appliedQuery.trim().isNotEmpty || _statusFilter != 'All';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusNodeChanged);
  }

  void _onFocusNodeChanged() {
    if (_searchFocusNode.hasFocus && !_isSearchFocused) {
      setState(() => _isSearchFocused = true);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _appliedQuery = value);
    });
    setState(() {});
  }

  void _applySearchNow() {
    _searchDebounce?.cancel();
    setState(() => _appliedQuery = _searchController.text);
  }

  void _expandSearch() {
    setState(() => _isSearchFocused = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _exitSearch() {
    _searchFocusNode.unfocus();
    _searchController.clear();
    _searchDebounce?.cancel();
    setState(() {
      _isSearchFocused = false;
      _appliedQuery = '';
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.removeListener(_onFocusNodeChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static bool _validPartition(List<Task> items) {
    var seenDone = false;
    for (final t in items) {
      if (t.status == 'Done') {
        seenDone = true;
      } else if (seenDone) {
        return false;
      }
    }
    return true;
  }

  void _onReorder(TaskProvider p, int oldIndex, int newIndex) {
    final items = List<Task>.from(p.allTasks);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    if (!_validPartition(items)) return;
    p.applyOrder(items);
  }

  Future<void> _openCreateScreen() async {
    final taskProvider = context.read<TaskProvider>();
    await Navigator.push(context, slideUpRoute(const TaskFormScreen()));
    if (!mounted) return;
    await taskProvider.reload();
  }

  Widget _buildTaskCountRow(TaskProvider p) {
    final filtered = p.getFiltered(_appliedQuery, _statusFilter);
    final total = p.allTasks.length;
    return Text(
      'Showing ${filtered.length} of $total tasks',
      style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF7A7A8C)),
    );
  }

  Widget _buildDefaultHeader(TaskProvider provider) {
    final titles = provider.allTasks.map((t) => t.title).toList();
    return Container(
      key: const ValueKey('default'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // "FLO" in white
              Text(
                'FLO',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF0F0F5),
                  height: 1.0, // remove extra line height
                ),
              ),
              // "DO" in blue
              Text(
                'DO',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3B9FE8),
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SearchRow(
            controller: _searchController,
            focusNode: _searchFocusNode,
            variant: SearchRowVariant.defaultStyle,
            onChanged: _onSearchChanged,
            onApply: _applySearchNow,
            onExpandSearch: _expandSearch,
            allTaskTitles: titles,
          ),
          const SizedBox(height: 10),
          FilterChipBar(
            selectedFilter: _statusFilter,
            onFilterChanged: (f) => setState(() => _statusFilter = f),
          ),
          const SizedBox(height: 6),
          _buildTaskCountRow(provider),
        ],
      ),
    );
  }

  Widget _buildFocusedSearchBar(TaskProvider provider) {
    return Container(
      key: const ValueKey('focused'),
      color: AppTheme.cBackground,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: SearchRow(
        controller: _searchController,
        focusNode: _searchFocusNode,
        variant: SearchRowVariant.focused,
        onChanged: _onSearchChanged,
        onApply: _applySearchNow,
        onBack: _exitSearch,
        allTaskTitles: provider.allTasks.map((t) => t.title).toList(),
      ),
    );
  }

  Widget _stagger(int index, Task task, Widget child) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('stagger-${task.id}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 60).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      builder: (context, value, c) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  Widget _taskTile(TaskProvider p, Task task, int index,
      {required bool allowReorder}) {
    final isBlocked = p.isBlocked(task);
    final blocker =
        task.blockedById != null ? p.getTaskById(task.blockedById!) : null;
    final card = TaskCard(
      task: task,
      isBlocked: isBlocked,
      blockerTitle: blocker?.title,
      highlightQuery: _appliedQuery,
      showDragHandle: allowReorder,
      dragIndex: index,
    );
    return _stagger(index, task, card);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearchFocused,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearchFocused) _exitSearch();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _isSearchFocused
                    ? Consumer<TaskProvider>(
                        builder: (context, provider, _) =>
                            _buildFocusedSearchBar(provider))
                    : Consumer<TaskProvider>(
                        builder: (context, provider, _) =>
                            _buildDefaultHeader(provider)),
              ),
              if (_isSearchFocused)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Consumer<TaskProvider>(
                    builder: (context, p, _) => _buildTaskCountRow(p),
                  ),
                ),
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (context, p, _) {
                    final filtered =
                        p.getFiltered(_appliedQuery, _statusFilter);
                    final isFiltered = _isFilterActive;
                    final allowReorder = !isFiltered;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isFiltered)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: Text(
                              'Drag to reorder is disabled while search or a status filter is active.',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppTheme.cTextMuted),
                            ),
                          ),
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollUpdateNotification) {
                                final d = notification.scrollDelta;
                                if (d != null && d > 0 && _isFabExtended) {
                                  setState(() => _isFabExtended = false);
                                } else if (d != null &&
                                    d < 0 &&
                                    !_isFabExtended) {
                                  setState(() => _isFabExtended = true);
                                }
                              }
                              return false;
                            },
                            child: filtered.isEmpty
                                ? EmptyState(isFiltered: isFiltered)
                                : allowReorder
                                    ? ReorderableListView.builder(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 12, 16, 100),
                                        buildDefaultDragHandles: false,
                                        proxyDecorator:
                                            (child, index, animation) {
                                          return AnimatedBuilder(
                                            animation: animation,
                                            builder: (context, _) {
                                              final t = CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeInOut);
                                              return Transform.scale(
                                                scale: 1.0 + 0.02 * t.value,
                                                child: Material(
                                                  elevation: 6 * t.value,
                                                  shadowColor: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  color: Colors.transparent,
                                                  child: child,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        itemCount: filtered.length,
                                        onReorder: (oldIdx, newIdx) =>
                                            _onReorder(p, oldIdx, newIdx),
                                        itemBuilder: (context, index) {
                                          final task = filtered[index];
                                          return Padding(
                                            key: ValueKey(task.id),
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: _taskTile(p, task, index,
                                                allowReorder: true),
                                          );
                                        },
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 12, 16, 100),
                                        itemCount: filtered.length,
                                        itemBuilder: (context, index) {
                                          final task = filtered[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: _taskTile(p, task, index,
                                                allowReorder: false),
                                          );
                                        },
                                      ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          key: const ValueKey('fab-compact'),
          onPressed: _openCreateScreen,
          backgroundColor: AppTheme.cPrimary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
