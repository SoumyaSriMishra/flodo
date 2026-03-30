import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders [text] with all occurrences of [query] highlighted.
/// Matching is case-insensitive.
/// Non-matching parts use [baseStyle]. Matching parts use [highlightStyle].
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? baseStyle;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.baseStyle,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase().trim();

    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final int matchIndex = lowerText.indexOf(lowerQuery, start);
      if (matchIndex == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        }
        break;
      }

      if (matchIndex > start) {
        spans.add(TextSpan(text: text.substring(start, matchIndex), style: baseStyle));
      }

      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + lowerQuery.length),
        style: highlightStyle ??
            GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B9FE8),
              backgroundColor: const Color(0xFF1A2A3A),
              fontSize: baseStyle?.fontSize,
            ),
      ));

      start = matchIndex + lowerQuery.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(children: spans),
    );
  }
}
