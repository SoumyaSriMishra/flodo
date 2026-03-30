import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class EmptyState extends StatefulWidget {
  final bool isFiltered;
  const EmptyState({super.key, this.isFiltered = false});

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isFiltered ? Icons.search_off_rounded : Icons.checklist_rounded,
                  size: 72,
                  color: AppTheme.cBorder,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isFiltered ? 'No matching tasks' : 'No tasks yet',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.cTextMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isFiltered ? 'Try a different search or filter' : 'Tap + to create your first task',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.cTextMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
