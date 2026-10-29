import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/wine.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

extension WineTypeDisplay on WineType {
  String displayName(AppLocalizations l10n) => switch (this) {
    WineType.red => l10n.typeRed,
    WineType.white => l10n.typeWhite,
    WineType.rose => l10n.typeRose,
    WineType.sparkling => l10n.typeSparkling,
    WineType.dessert => l10n.typeDessert,
    WineType.fortified => l10n.typeFortified,
  };

  Color get color => switch (this) {
    WineType.red => const Color(0xFF8E1B3A),
    WineType.white => const Color(0xFFE3C95F),
    WineType.rose => const Color(0xFFF08FA6),
    WineType.sparkling => const Color(0xFFF2E3A0),
    WineType.dessert => const Color(0xFFC98B2B),
    WineType.fortified => const Color(0xFF5C2A1E),
  };
}

extension DrinkingStatusDisplay on DrinkingStatus {
  String displayName(AppLocalizations l10n) => switch (this) {
    DrinkingStatus.unknown => l10n.statusUnknown,
    DrinkingStatus.tooEarly => l10n.statusTooEarly,
    DrinkingStatus.ready => l10n.statusReady,
    DrinkingStatus.pastPeak => l10n.statusPastPeak,
  };

  /// Text and background color for this status in the current theme.
  (Color, Color) colors(BuildContext context) {
    final c = CellarColors.of(context);
    return switch (this) {
      DrinkingStatus.unknown => (c.unknown, c.unknownContainer),
      DrinkingStatus.tooEarly => (c.tooEarly, c.tooEarlyContainer),
      DrinkingStatus.ready => (c.ready, c.readyContainer),
      DrinkingStatus.pastPeak => (c.pastPeak, c.pastPeakContainer),
    };
  }
}

/// Formats an amount in the app's current language, without currency symbol.
String formatMoney(BuildContext context, double value) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: value % 1 == 0 ? 0 : 2,
  ).format(value);
}

/// "Rack A · Shelf 2 · Position 4", leaving out the parts that are not set.
String formatLocation(AppLocalizations l10n, Wine wine) => [
  if (wine.rack != null) '${l10n.rack} ${wine.rack}',
  if (wine.shelf != null) '${l10n.shelf} ${wine.shelf}',
  if (wine.position != null) '${l10n.position} ${wine.position}',
].join(' · ');

class DrinkingStatusChip extends StatelessWidget {
  const DrinkingStatusChip({super.key, required this.status});

  final DrinkingStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (foreground, background) = status.colors(context);
    final duration = Motion.of(context, Motion.medium);
    return AnimatedContainer(
      duration: duration,
      curve: Motion.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedDefaultTextStyle(
        duration: duration,
        curve: Motion.easeOut,
        style: Theme.of(context).textTheme.labelMedium!
            .copyWith(color: foreground, fontWeight: FontWeight.w600),
        child: Text(status.displayName(l10n)),
      ),
    );
  }
}

/// A round badge in the wine's color with a glass icon. Decorative: screen
/// readers skip it, since the wine type is read out elsewhere.
class WineTypeBadge extends StatelessWidget {
  const WineTypeBadge({super.key, required this.type, this.size = 44});

  final WineType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final light =
        ThemeData.estimateBrightnessForColor(type.color) == Brightness.light;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: type.color, shape: BoxShape.circle),
        child: Icon(
          Icons.wine_bar,
          size: size * 0.5,
          color: light ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
}

/// A date like "14 mars 2026", in the app's current language.
String formatDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).format(date);
}

/// "14 mars 2026 · Systembolaget", leaving out the parts that are not set.
String formatPurchase(BuildContext context, Wine wine) => [
  if (wine.purchaseDate != null) formatDate(context, wine.purchaseDate!),
  if (wine.purchasedFrom != null) wine.purchasedFrom!,
].join(' · ');
