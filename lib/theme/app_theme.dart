import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import 'motion.dart';

/// The app's light and dark themes. Colors are picked by hand rather than
/// generated, so that all text has high contrast (tested in
/// test/theme_test.dart).
abstract final class AppTheme {
  static const _bordeaux = Color(0xFF6B1530);
  static const _cellarBordeaux = Color(0xFF5E1226);

  /// Text and icons on the bordeaux app bar and navigation bar.
  static const champagne = Color(0xFFF1E3C2);

  /// "Bordeaux frames": warm ivory with bordeaux and champagne gold.
  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _bordeaux,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: champagne,
    onPrimaryContainer: Color(0xFF3A2A05),
    secondary: Color(0xFF7A5A12),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: champagne,
    onSecondaryContainer: Color(0xFF3A2A05),
    tertiary: Color(0xFF7A5A12),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: champagne,
    onTertiaryContainer: Color(0xFF3A2A05),
    error: Color(0xFF9A1D16),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFBF8F1),
    onSurface: Color(0xFF1F1A17),
    onSurfaceVariant: Color(0xFF4F463F),
    outline: Color(0xFF80766C),
    outlineVariant: Color(0xFFDED5C7),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F2E8),
    surfaceContainer: Color(0xFFF2ECE0),
    surfaceContainerHigh: Color(0xFFECE5D7),
    surfaceContainerHighest: Color(0xFFE6DECE),
    inverseSurface: Color(0xFF332D29),
    onInverseSurface: Color(0xFFF7F0E6),
    inversePrimary: Color(0xFFE6C77F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0x00000000),
  );

  /// "The cellar": oxblood black with gold and bordeaux.
  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFD9B46A),
    onPrimary: Color(0xFF2E2200),
    primaryContainer: _cellarBordeaux,
    onPrimaryContainer: Color(0xFFF5DDA8),
    secondary: Color(0xFFD9B46A),
    onSecondary: Color(0xFF2E2200),
    secondaryContainer: _cellarBordeaux,
    onSecondaryContainer: Color(0xFFF5DDA8),
    tertiary: Color(0xFFD9B46A),
    onTertiary: Color(0xFF2E2200),
    tertiaryContainer: _cellarBordeaux,
    onTertiaryContainer: Color(0xFFF5DDA8),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1A0E11),
    onSurface: Color(0xFFF2E8DC),
    onSurfaceVariant: Color(0xFFD6C5BA),
    outline: Color(0xFF9E8A84),
    outlineVariant: Color(0xFF4C3236),
    surfaceContainerLowest: Color(0xFF12090B),
    surfaceContainerLow: Color(0xFF261519),
    surfaceContainer: Color(0xFF2C1A1E),
    surfaceContainerHigh: Color(0xFF362226),
    surfaceContainerHighest: Color(0xFF412A2F),
    inverseSurface: Color(0xFFF2E8DC),
    onInverseSurface: Color(0xFF2C1A1E),
    inversePrimary: _bordeaux,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0x00000000),
  );

  static ThemeData light() => _build(lightScheme, CellarColors.light);

  static ThemeData dark() => _build(darkScheme, CellarColors.dark);

  static ThemeData _build(ColorScheme scheme, CellarColors cellarColors) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    // In light mode the app bar and navigation bar are filled bordeaux.
    final light = scheme.brightness == Brightness.light;
    final barColor = light ? scheme.primary : scheme.surface;
    final onBar = light ? champagne : scheme.onSurface;
    final text = base.textTheme;
    final rounded12 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [cellarColors],
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: barColor,
        foregroundColor: onBar,
        // Light status bar icons, on the bordeaux bar and on the dark theme.
        systemOverlayStyle: SystemUiOverlayStyle.light,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          color: onBar,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      // Filled fields with the label inside; a line at the bottom shows focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: rounded12,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: rounded12,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: rounded12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: light ? barColor : scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : (light ? champagne : scheme.onSurfaceVariant),
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(
            color: light ? champagne : scheme.onSurface,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded12,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // iOS keeps its native slide so the swipe-back gesture works.
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// A new page fades in while sliding a short distance up; the old page
/// stays still. Instant when the user has turned off animations.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Duration get transitionDuration => Motion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.easeOut,
      reverseCurve: Motion.easeOut.flipped,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Colors for the wine-specific parts of the UI, tuned for each theme.
@immutable
class CellarColors extends ThemeExtension<CellarColors> {
  const CellarColors({
    required this.ready,
    required this.readyContainer,
    required this.tooEarly,
    required this.tooEarlyContainer,
    required this.pastPeak,
    required this.pastPeakContainer,
    required this.unknown,
    required this.unknownContainer,
    required this.star,
  });

  // Each status has a text color and a background color with high contrast
  // between them.
  final Color ready;
  final Color readyContainer;
  final Color tooEarly;
  final Color tooEarlyContainer;
  final Color pastPeak;
  final Color pastPeakContainer;
  final Color unknown;
  final Color unknownContainer;

  final Color star;

  static const light = CellarColors(
    ready: Color(0xFF145218),
    readyContainer: Color(0xFFDCEFD8),
    tooEarly: Color(0xFF0B3D8C),
    tooEarlyContainer: Color(0xFFDCE7F7),
    pastPeak: Color(0xFF732F00),
    pastPeakContainer: Color(0xFFFBE3CF),
    unknown: Color(0xFF4D4447),
    unknownContainer: Color(0xFFECE6E8),
    star: Color(0xFF7A5C00),
  );

  static const dark = CellarColors(
    ready: Color(0xFFA5D6A7),
    readyContainer: Color(0xFF1E3320),
    tooEarly: Color(0xFFA8C8F5),
    tooEarlyContainer: Color(0xFF1C2A40),
    pastPeak: Color(0xFFFFC28F),
    pastPeakContainer: Color(0xFF3D2512),
    unknown: Color(0xFFD3C3C7),
    unknownContainer: Color(0xFF2D2829),
    star: Color(0xFFE3C47E),
  );

  static CellarColors of(BuildContext context) =>
      Theme.of(context).extension<CellarColors>()!;

  @override
  CellarColors copyWith() => this;

  @override
  CellarColors lerp(CellarColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return CellarColors(
      ready: mix(ready, other.ready),
      readyContainer: mix(readyContainer, other.readyContainer),
      tooEarly: mix(tooEarly, other.tooEarly),
      tooEarlyContainer: mix(tooEarlyContainer, other.tooEarlyContainer),
      pastPeak: mix(pastPeak, other.pastPeak),
      pastPeakContainer: mix(pastPeakContainer, other.pastPeakContainer),
      unknown: mix(unknown, other.unknown),
      unknownContainer: mix(unknownContainer, other.unknownContainer),
      star: mix(star, other.star),
    );
  }
}
