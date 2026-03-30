import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'highlighted_text.dart';

enum SearchRowVariant { defaultStyle, focused }

/// Search row with overlay autocomplete (max 5) and a compact circular submit control.
/// Debounced filtering is handled by the parent via [onChanged]; [onApply] commits immediately.
class SearchRow extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final SearchRowVariant variant;
  final ValueChanged<String> onChanged;
  final VoidCallback onApply;
  final List<String> allTaskTitles;
  final VoidCallback? onExpandSearch;
  final VoidCallback? onBack;

  const SearchRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.variant,
    required this.onChanged,
    required this.onApply,
    required this.allTaskTitles,
    this.onExpandSearch,
    this.onBack,
  });

  @override
  State<SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends State<SearchRow> {
  String _currentQuery = '';
  List<String> _suggestions = [];

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onControllerChanged);
    _currentQuery = widget.controller.text;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onControllerChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _hideSuggestions();
      });
    }
  }

  void _onControllerChanged() {
    final value = widget.controller.text;
    final newSuggestions = _computeSuggestions(value);
    final show = value.trim().isNotEmpty && newSuggestions.isNotEmpty;

    setState(() {
      _currentQuery = value;
      _suggestions = newSuggestions;
    });

    widget.onChanged(value);

    if (show && widget.variant == SearchRowVariant.defaultStyle) {
      _ensureOverlay();
    } else {
      _hideSuggestions();
    }
  }

  List<String> _computeSuggestions(String query) {
    if (query.trim().isEmpty) return [];
    final lowerQuery = query.toLowerCase().trim();
    return widget.allTaskTitles
        .where((title) => title.toLowerCase().contains(lowerQuery))
        .take(5)
        .toList();
  }

  void _applySearch() {
    _hideSuggestions();
    FocusScope.of(context).unfocus();
    widget.onApply();
  }

  void _onSuggestionTapped(String suggestion) {
    widget.controller.text = suggestion;
    _currentQuery = suggestion;
    _hideSuggestions();
    FocusScope.of(context).unfocus();
    widget.onChanged(suggestion);
    widget.onApply();
    setState(() {});
  }

  void _clearSearch() {
    widget.controller.clear();
    _currentQuery = '';
    _hideSuggestions();
    widget.onChanged('');
    widget.onApply();
    widget.focusNode.requestFocus();
    setState(() {});
  }

  void _ensureOverlay() {
    if (_overlayEntry == null) {
      _overlayEntry = _buildOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _hideSuggestions() {
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.sizeOf(context).width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            color: Colors.transparent,
            child: _SuggestionsDropdown(
              suggestions: _suggestions,
              query: _currentQuery,
              onTap: _onSuggestionTapped,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFocusedVariant = widget.variant == SearchRowVariant.focused;
    return CompositedTransformTarget(
      link: _layerLink,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                autofocus: isFocusedVariant,
                onChanged: (_) {},
                onSubmitted: (_) => _applySearch(),
                onTap: isFocusedVariant ? null : () => widget.onExpandSearch?.call(),
                textInputAction: TextInputAction.search,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: const Color(0xFFF0F0F5),
                ),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: const Color(0xFF7A7A8C),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF7A7A8C),
                    size: 22,
                  ),
                  suffixIcon: _currentQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF7A7A8C),
                          ),
                          onPressed: _clearSearch,
                          splashRadius: 16,
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF1E1E22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          if (isFocusedVariant)
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: GestureDetector(
                onTap: () {
                  widget.onBack?.call();
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: const Color(0xFF3B9FE8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionsDropdown extends StatelessWidget {
  final List<String> suggestions;
  final String query;
  final ValueChanged<String> onTap;

  const _SuggestionsDropdown({
    required this.suggestions,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A30)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: Color(0xFF2A2A30),
          ),
          itemBuilder: (_, index) {
            final title = suggestions[index];
            return InkWell(
              onTap: () => onTap(title),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: Color(0xFF4A4A5A),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HighlightedText(
                        text: title,
                        query: query,
                        baseStyle: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: const Color(0xFFF0F0F5),
                        ),
                        highlightStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B9FE8),
                          backgroundColor: const Color(0xFF1A2A3A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.north_west_rounded,
                      size: 14,
                      color: Color(0xFF4A4A5A),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
