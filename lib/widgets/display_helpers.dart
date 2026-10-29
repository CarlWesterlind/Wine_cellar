import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/wine.dart';

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

  MaterialColor get color => switch (this) {
    DrinkingStatus.unknown => Colors.grey,
    DrinkingStatus.tooEarly => Colors.blue,
    DrinkingStatus.ready => Colors.green,
    DrinkingStatus.pastPeak => Colors.orange,
  };
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName(l10n),
        style: TextStyle(
          color: status.color.shade800,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
