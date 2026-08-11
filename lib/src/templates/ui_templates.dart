import '../project_config.dart';
import '../version.dart';

String uiPubspec(ProjectConfig c) => '''
name: ${c.ui}
description: Shared UI components for ${c.pascal}.
publish_to: 'none'
version: 0.1.0
resolution: workspace

environment:
  sdk: $generatedSdkConstraint

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ${c.versions['flutter_lints']}

flutter:
  assets:
    - assets/icons/
    - assets/images/
  # fonts:
  #   - family: Poppins
  #     fonts:
  #       - asset: assets/fonts/Poppins-Regular.ttf
  #       - asset: assets/fonts/Poppins-Medium.ttf
  #         weight: 500
  #       - asset: assets/fonts/Poppins-SemiBold.ttf
  #         weight: 600
  #       - asset: assets/fonts/Poppins-Bold.ttf
  #         weight: 700
''';

/// Starter widget test for the shared UI package.
String uiStarterTest(ProjectConfig c) => '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:${c.ui}/${c.ui}.dart';

void main() {
  group('AppTheme', () {
    test('light and dark are Material 3 and differ in brightness', () {
      expect(AppTheme.light.useMaterial3, isTrue);
      expect(AppTheme.dark.useMaterial3, isTrue);
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
    });
  });

  group('Breakpoints', () {
    testWidgets('ResponsiveBuilder selects by available width', (tester) async {
      Widget sized(double width) => MaterialApp(
            home: Center(
              child: SizedBox(
                width: width,
                child: ResponsiveBuilder(
                  mobile: (_) => const Text('mobile'),
                  tablet: (_) => const Text('tablet'),
                  desktop: (_) => const Text('desktop'),
                ),
              ),
            ),
          );

      // Widths stay inside the default 800x600 test surface, which would
      // otherwise clamp the SizedBox and defeat the assertion.
      await tester.pumpWidget(sized(400));
      expect(find.text('mobile'), findsOneWidget);

      await tester.pumpWidget(sized(Breakpoints.mobile + 100));
      expect(find.text('tablet'), findsOneWidget);
    });
  });
}
''';

String uiBarrel() => '''
// ── Assets ───────────────────────────────────────────────
export 'assets/app_fonts.dart';
export 'assets/app_icons.dart';
export 'assets/app_images.dart';

// ── Responsive ───────────────────────────────────────────
export 'responsive/breakpoints.dart';
export 'responsive/responsive_builder.dart';
export 'responsive/responsive_helper.dart';

// ── Theme ────────────────────────────────────────────────
export 'theme/app_colors.dart';
export 'theme/app_spacing.dart';
export 'theme/app_theme.dart';
export 'theme/app_typography.dart';
''';

String appIcons(ProjectConfig c) => '''
abstract final class AppIcons {
  // ignore: unused_field — used when real icon constants are added
  static const String _base = 'assets/icons';

  // static const String home = '\$_base/home.svg';
}
''';

String appImages(ProjectConfig c) => '''
abstract final class AppImages {
  // ignore: unused_field — used when real image constants are added
  static const String _base = 'assets/images';

  // static const String logo = '\$_base/logo.png';
}
''';

String appFonts() => '''
abstract final class AppFonts {
  // static const String primary = 'Poppins';
}
''';

String breakpoints() => '''
abstract final class Breakpoints {
  static const double mobileSmall = 360;
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

enum ScreenType { mobileSmall, mobile, tablet, desktop }
''';

String responsiveHelper() => '''
import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

extension ResponsiveHelper on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  ScreenType get screenType {
    final width = screenWidth;
    if (width <= Breakpoints.mobileSmall) return ScreenType.mobileSmall;
    if (width <= Breakpoints.mobile) return ScreenType.mobile;
    if (width <= Breakpoints.tablet) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  bool get isMobileSmall => screenWidth <= Breakpoints.mobileSmall;
  bool get isMobile => screenWidth <= Breakpoints.mobile;
  bool get isTablet =>
      screenWidth > Breakpoints.mobile && screenWidth <= Breakpoints.tablet;
  bool get isDesktop => screenWidth > Breakpoints.tablet;

  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) =>
      switch (screenType) {
        ScreenType.desktop => desktop ?? tablet ?? mobile,
        ScreenType.tablet => tablet ?? mobile,
        _ => mobile,
      };

  EdgeInsets get safeAreaPadding => MediaQuery.paddingOf(this);
  double get topSafeArea => safeAreaPadding.top;
  double get bottomSafeArea => safeAreaPadding.bottom;
}
''';

String responsiveBuilder() => '''
import 'package:flutter/widgets.dart';

import 'breakpoints.dart';
import 'responsive_helper.dart';

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > Breakpoints.tablet && desktop != null) {
          return desktop!(context);
        }
        if (constraints.maxWidth > Breakpoints.mobile && tablet != null) {
          return tablet!(context);
        }
        return mobile(context);
      },
    );
  }
}

class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({
    super.key,
    required this.child,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget child;
  final EdgeInsetsGeometry mobile;
  final EdgeInsetsGeometry? tablet;
  final EdgeInsetsGeometry? desktop;

  @override
  Widget build(BuildContext context) {
    final padding = context.responsive<EdgeInsetsGeometry>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return Padding(padding: padding, child: child);
  }
}
''';

String appColors() => '''
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryLight = Color(0xFF4DA3FF);
  static const Color primaryDark = Color(0xFF0D47A1);

  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF64D8CB);
  static const Color secondaryDark = Color(0xFF00766C);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color backgroundDark = Color(0xFF121212);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);

  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
}
''';

String appSpacing() => '''
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double screenPadding = md;

  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
}
''';

String appTypography() => '''
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static const String _fontFamily = 'Roboto';

  static TextTheme get lightTextTheme => const TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily, fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.12, color: AppColors.textPrimary),
    displayMedium: TextStyle(fontFamily: _fontFamily, fontSize: 45, fontWeight: FontWeight.w400, height: 1.16, color: AppColors.textPrimary),
    displaySmall: TextStyle(fontFamily: _fontFamily, fontSize: 36, fontWeight: FontWeight.w400, height: 1.22, color: AppColors.textPrimary),
    headlineLarge: TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w600, height: 1.25, color: AppColors.textPrimary),
    headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w600, height: 1.29, color: AppColors.textPrimary),
    headlineSmall: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600, height: 1.33, color: AppColors.textPrimary),
    titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w600, height: 1.27, color: AppColors.textPrimary),
    titleMedium: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.50, color: AppColors.textPrimary),
    titleSmall: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43, color: AppColors.textPrimary),
    bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.50, color: AppColors.textPrimary),
    bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.43, color: AppColors.textSecondary),
    bodySmall: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.33, color: AppColors.textSecondary),
    labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.43, color: AppColors.textPrimary),
    labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.33, color: AppColors.textSecondary),
    labelSmall: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.45, color: AppColors.textSecondary),
  );

  static TextTheme get darkTextTheme => const TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily, fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.12, color: AppColors.textPrimaryDark),
    displayMedium: TextStyle(fontFamily: _fontFamily, fontSize: 45, fontWeight: FontWeight.w400, height: 1.16, color: AppColors.textPrimaryDark),
    displaySmall: TextStyle(fontFamily: _fontFamily, fontSize: 36, fontWeight: FontWeight.w400, height: 1.22, color: AppColors.textPrimaryDark),
    headlineLarge: TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w600, height: 1.25, color: AppColors.textPrimaryDark),
    headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w600, height: 1.29, color: AppColors.textPrimaryDark),
    headlineSmall: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600, height: 1.33, color: AppColors.textPrimaryDark),
    titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w600, height: 1.27, color: AppColors.textPrimaryDark),
    titleMedium: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.50, color: AppColors.textPrimaryDark),
    titleSmall: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43, color: AppColors.textPrimaryDark),
    bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.50, color: AppColors.textPrimaryDark),
    bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.43, color: AppColors.textSecondaryDark),
    bodySmall: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.33, color: AppColors.textSecondaryDark),
    labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.43, color: AppColors.textPrimaryDark),
    labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.33, color: AppColors.textSecondaryDark),
    labelSmall: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.45, color: AppColors.textSecondaryDark),
  );
}
''';

// app_theme.dart is large — keep it in its own function
String appTheme() => r'''
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static final _shapeMedium = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd));
  static final _shapeLarge = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg));
  static final _shapeXl = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl));
  static final _shapeSmall = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm));
  static const _buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + AppSpacing.xs);

  static ThemeData get light => ThemeData(
    useMaterial3: true, brightness: Brightness.light, colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background, textTheme: AppTypography.lightTextTheme,
    appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 0.5, centerTitle: true, backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, padding: _buttonPadding, shape: _shapeMedium)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, padding: _buttonPadding, shape: _shapeMedium, side: const BorderSide(color: AppColors.primary))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: _buttonPadding, shape: _shapeMedium)),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(padding: _buttonPadding, shape: _shapeMedium)),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(shape: _shapeMedium)),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: _shapeLarge, elevation: 4),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.primary, width: 2)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.error)), contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xs)),
    cardTheme: CardThemeData(elevation: 1, shape: _shapeMedium, color: AppColors.surface),
    dialogTheme: DialogThemeData(elevation: 6, shape: _shapeXl, backgroundColor: AppColors.surface),
    bottomSheetTheme: const BottomSheetThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))), backgroundColor: AppColors.surface, showDragHandle: true),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: _shapeMedium),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(type: BottomNavigationBarType.fixed, selectedItemColor: AppColors.primary, unselectedItemColor: AppColors.textSecondary, showUnselectedLabels: true, elevation: 8),
    navigationBarTheme: NavigationBarThemeData(elevation: 3, indicatorColor: AppColors.primary.withValues(alpha: 0.12), labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected),
    navigationRailTheme: NavigationRailThemeData(indicatorColor: AppColors.primary.withValues(alpha: 0.12), selectedIconTheme: const IconThemeData(color: AppColors.primary), unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary)),
    tabBarTheme: const TabBarThemeData(labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary, indicatorColor: AppColors.primary),
    drawerTheme: const DrawerThemeData(elevation: 1, backgroundColor: AppColors.surface),
    checkboxTheme: CheckboxThemeData(shape: _shapeSmall, fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primary : null)),
    radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primary : null)),
    switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primary : null), trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primary.withValues(alpha: 0.5) : null)),
    dividerTheme: DividerThemeData(color: AppColors.textSecondary.withValues(alpha: 0.12), thickness: 1, space: 1),
    chipTheme: ChipThemeData(shape: _shapeMedium, side: BorderSide.none),
    tooltipTheme: TooltipThemeData(decoration: BoxDecoration(color: AppColors.textPrimary, borderRadius: BorderRadius.circular(AppSpacing.radiusSm))),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark, textTheme: AppTypography.darkTextTheme,
    appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 0.5, centerTitle: true, backgroundColor: AppColors.surfaceDark, foregroundColor: AppColors.textPrimaryDark),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, padding: _buttonPadding, shape: _shapeMedium)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryLight, padding: _buttonPadding, shape: _shapeMedium, side: const BorderSide(color: AppColors.primaryLight))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight, padding: _buttonPadding, shape: _shapeMedium)),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(padding: _buttonPadding, shape: _shapeMedium)),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(shape: _shapeMedium)),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: _shapeLarge, elevation: 4),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: AppColors.surfaceDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: AppColors.textSecondaryDark.withValues(alpha: 0.3))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.primaryLight, width: 2)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.error)), contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xs)),
    cardTheme: CardThemeData(elevation: 1, shape: _shapeMedium, color: AppColors.surfaceDark),
    dialogTheme: DialogThemeData(elevation: 6, shape: _shapeXl, backgroundColor: AppColors.surfaceDark),
    bottomSheetTheme: const BottomSheetThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))), backgroundColor: AppColors.surfaceDark, showDragHandle: true),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: _shapeMedium),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(type: BottomNavigationBarType.fixed, selectedItemColor: AppColors.primaryLight, unselectedItemColor: AppColors.textSecondaryDark, showUnselectedLabels: true, elevation: 8),
    navigationBarTheme: NavigationBarThemeData(elevation: 3, indicatorColor: AppColors.primaryLight.withValues(alpha: 0.12), labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected),
    navigationRailTheme: NavigationRailThemeData(indicatorColor: AppColors.primaryLight.withValues(alpha: 0.12), selectedIconTheme: const IconThemeData(color: AppColors.primaryLight), unselectedIconTheme: const IconThemeData(color: AppColors.textSecondaryDark)),
    tabBarTheme: const TabBarThemeData(labelColor: AppColors.primaryLight, unselectedLabelColor: AppColors.textSecondaryDark, indicatorColor: AppColors.primaryLight),
    drawerTheme: const DrawerThemeData(elevation: 1, backgroundColor: AppColors.surfaceDark),
    checkboxTheme: CheckboxThemeData(shape: _shapeSmall, fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primaryLight : null)),
    radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primaryLight : null)),
    switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primaryLight : null), trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primaryLight.withValues(alpha: 0.5) : null)),
    dividerTheme: DividerThemeData(color: AppColors.textSecondaryDark.withValues(alpha: 0.12), thickness: 1, space: 1),
    chipTheme: ChipThemeData(shape: _shapeMedium, side: BorderSide.none),
    tooltipTheme: TooltipThemeData(decoration: BoxDecoration(color: AppColors.textPrimaryDark, borderRadius: BorderRadius.circular(AppSpacing.radiusSm))),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryLight),
  );
}
''';

String uiPackageMd(ProjectConfig c) => '''
# ${c.ui}

Shared UI components, themes, design tokens, responsive utilities, and centralized assets.

## What belongs here

- Full Material 3 theme (light + dark)
- Color palette, typography, spacing constants
- Responsive utilities (Breakpoints, ResponsiveHelper, ResponsiveBuilder)
- All asset files (icons, images, fonts) + type-safe constants
- Reusable stateless widgets in `widgets/`

## What is PROHIBITED

- GetX, business logic, HTTP clients, localization, screen-level widgets
''';
