import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/cellar_services.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/csv.dart';
import '../models/dates.dart';
import '../models/wine.dart';
import '../state/cellar_controller.dart';
import '../widgets/display_helpers.dart';

/// Shares all wines as a CSV file. The share sheet points at [context]'s
/// widget on tablets.
Future<void> exportCellar(
  BuildContext context,
  CellarController cellar,
  CellarServices services,
) async {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toString();
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  final wines = cellar.allWines;
  await tryOrShowError(
    context,
    () => services.shareFile(
      cellarCsv(l10n, locale, wines),
      fileName: '${l10n.exportFileName}.csv',
      mimeType: 'text/csv',
      origin: origin,
    ),
  );
}

/// [wines] as CSV, with column names in the app's language. Starts with a
/// byte order mark so Excel reads å, æ and ø correctly.
Uint8List cellarCsv(AppLocalizations l10n, String locale, List<Wine> wines) {
  final number = NumberFormat('0.##', locale);
  String text(Object? value) => switch (value) {
    null => '',
    double() => number.format(value),
    DateTime() => toIsoDate(value),
    _ => '$value',
  };

  final rows = [
    [
      l10n.wineName,
      l10n.producer,
      l10n.vintage,
      l10n.wineType,
      l10n.country,
      l10n.region,
      l10n.grapes,
      l10n.quantity,
      l10n.price,
      l10n.rack,
      l10n.shelf,
      l10n.position,
      l10n.drinkFrom,
      l10n.drinkUntil,
      l10n.purchaseDate,
      l10n.purchasedFrom,
    ],
    for (final wine in wines)
      [
        for (final value in <Object?>[
          wine.name,
          wine.producer,
          wine.vintage,
          wine.type.displayName(l10n),
          wine.country,
          wine.region,
          wine.grapes.join(', '),
          wine.quantity,
          wine.price,
          wine.rack,
          wine.shelf,
          wine.position,
          wine.drinkFrom,
          wine.drinkUntil,
          wine.purchaseDate,
          wine.purchasedFrom,
        ])
          text(value),
      ],
  ];
  return Uint8List.fromList(utf8.encode('﻿${toCsv(rows)}'));
}
