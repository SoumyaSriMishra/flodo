import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  static const List<String> _filters = ['All', 'To-Do', 'In Progress', 'Done'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 16, right: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final f = _filters[index];
          final selected = f == selectedFilter;
          return GestureDetector(
            onTap: () => onFilterChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppTheme.cPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: selected ? null : Border.all(color: AppTheme.cBorder),
              ),
              alignment: Alignment.center,
              child: Text(
                f,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.cTextSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
      ),
    );
  }
}

