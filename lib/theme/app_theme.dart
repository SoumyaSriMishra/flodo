import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const cBackground = Color(0xFF0D0D0F);
  static const cSurface = Color(0xFF161618);
  static const cSurfaceElevated = Color(0xFF1E1E22);
  static const cPrimary = Color(0xFF3B9FE8);
  static const cPrimaryLight = Color(0xFF6BBCF5);
  static const cBorder = Color(0xFF2A2A30);
  static const cError = Color(0xFFE05C6A);
  static const cSuccess = Color(0xFF3BCFA8);
  static const cWarning = Color(0xFFE8A83B);
  static const cTextPrimary = Color(0xFFF0F0F5);
  static const cTextSecondary = Color(0xFF7A7A8C);
  static const cTextMuted = Color(0xFF4A4A5A);

  static const double fsTitle = 32;
  static const double fsLabel = 12;
  static const double fsBody = 15;
  static const double fsSmall = 13;

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: cBackground,
    colorScheme: const ColorScheme.dark(
      primary: cPrimary,
      secondary: cPrimaryLight,
      surface: cSurface,
      error: cError,
      onPrimary: Colors.white,
      onSurface: cTextPrimary,
    ),
    cardTheme: CardThemeData(
      color: cSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: cBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cSurfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cError),
      ),
      hintStyle: const TextStyle(color: cTextMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: cTextPrimary,
      ),
      iconTheme: const IconThemeData(color: cTextPrimary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cSurfaceElevated,
      contentTextStyle: GoogleFonts.dmSans(color: cTextPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerTheme: const DividerThemeData(color: cBorder, thickness: 1, space: 1),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.spaceGrotesk(fontSize: fsTitle, fontWeight: FontWeight.w700, color: cTextPrimary),
      titleLarge: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: cTextPrimary),
      bodyMedium: GoogleFonts.dmSans(fontSize: fsBody, fontWeight: FontWeight.w400, color: cTextPrimary),
      bodySmall: GoogleFonts.dmSans(fontSize: fsSmall, fontWeight: FontWeight.w400, color: cTextSecondary),
      labelMedium: GoogleFonts.spaceGrotesk(fontSize: fsLabel, fontWeight: FontWeight.w500, color: cTextSecondary),
    ),
  );

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? cError : cPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
      ),
    );
  }
}
