import 'package:flutter/material.dart';

class AppColors {
  static const brand = Color(0xFF2563EB);
  static const brandDark = Color(0xFF1D4ED8);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const fieldFill = Color(0xFFF1F5F9);

  static const pending = Color(0xFFF59E0B);
  static const accepted = Color(0xFF3B82F6);
  static const onTheWay = Color(0xFFF97316);
  static const inProgress = Color(0xFF8B5CF6);
  static const completed = Color(0xFF10B981);
  static const rejected = Color(0xFFEF4444);

  static Color forStatus(String? status) {
    return switch (status) {
      'pending' => pending,
      'accepted' => accepted,
      'on_the_way' => onTheWay,
      'in_progress' => inProgress,
      'completed' => completed,
      'rejected' || 'cancelled' => rejected,
      _ => textMuted,
    };
  }

  static Color tint(Color c, [double alpha = 0.12]) => c.withValues(alpha: alpha);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    primary: AppColors.brand,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
  );

  const baseTextStyle = TextStyle(color: AppColors.textPrimary, height: 1.3);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    splashFactory: InkRipple.splashFactory,

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
      bodySmall: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    ).apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black12,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: AppColors.brand, fontSize: 13, fontWeight: FontWeight.w500),
      prefixIconColor: AppColors.textSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.rejected, width: 1.2),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.fieldFill,
      selectedColor: AppColors.brand,
      labelStyle: baseTextStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      showCheckmark: false,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.brand,
      unselectedItemColor: AppColors.textMuted,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.brand,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: AppColors.brand,
      dividerColor: AppColors.border,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textSecondary,
      horizontalTitleGap: 12,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actionTextColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      contentTextStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brand,
    ),
  );
}
