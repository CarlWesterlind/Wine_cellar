import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/label_scan.dart';
import '../models/sommelier_info.dart';
import '../models/wine.dart';

/// Why a label could not be scanned.
enum ScanFailure {
  notWineLabel,
  unreadable,
  dailyLimit,
  imageTooLarge,
  unsupportedImage,
  unavailable,
}

class LabelScanException implements Exception {
  const LabelScanException(this.reason, {this.limit});

  final ScanFailure reason;

  /// Scans allowed per day, for [ScanFailure.dailyLimit].
  final int? limit;

  @override
  String toString() => 'LabelScanException($reason)';
}

/// Reads a wine label from photos of the front and, optionally, the back.
abstract interface class LabelScanner {
  /// Descriptive text comes back in [language] (sv, da, nb or en). Throws
  /// [LabelScanException] when the label can't be read.
  Future<LabelScan> scan({
    required Uint8List front,
    Uint8List? back,
    required String language,
  });
}

/// The image type of [bytes] from its first bytes, or null if it isn't
/// JPEG, PNG or WebP.
String? imageMediaType(Uint8List bytes) {
  bool startsWith(List<int> prefix, [int offset = 0]) {
    if (bytes.length < offset + prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[offset + i] != prefix[i]) return false;
    }
    return true;
  }

  if (startsWith([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (startsWith(ascii.encode('RIFF')) && startsWith(ascii.encode('WEBP'), 8)) {
    return 'image/webp';
  }
  return null;
}

/// Calls the `scan-label` Supabase Edge Function, which asks Claude.
class SupabaseLabelScanner implements LabelScanner {
  SupabaseLabelScanner(this._functions);

  final FunctionsClient _functions;

  @override
  Future<LabelScan> scan({
    required Uint8List front,
    Uint8List? back,
    required String language,
  }) async {
    final mediaType = imageMediaType(front);
    // Both photos are sent with one media type, so they must match.
    if (mediaType == null ||
        (back != null && imageMediaType(back) != mediaType)) {
      throw const LabelScanException(ScanFailure.unsupportedImage);
    }

    final FunctionResponse response;
    try {
      response = await _functions.invoke(
        'scan-label',
        body: {
          'front': base64Encode(front),
          if (back != null) 'back': base64Encode(back),
          'mediaType': mediaType,
          'language': language,
        },
      );
    } on FunctionsFetchException {
      // No connection; shown as a network error.
      rethrow;
    } on FunctionException catch (e) {
      throw _failure(e);
    }

    final data = response.data;
    if (data is! Map<String, dynamic> || data['scan'] is! Map) {
      throw const LabelScanException(ScanFailure.unavailable);
    }
    try {
      return LabelScan.fromMap(data['scan'] as Map<String, dynamic>);
    } on FormatException {
      throw const LabelScanException(ScanFailure.unavailable);
    }
  }

  static LabelScanException _failure(FunctionException e) {
    final details = e.details;
    final code = details is Map ? details['error'] : null;
    return switch (code) {
      'not_wine_label' => const LabelScanException(ScanFailure.notWineLabel),
      'unreadable' => const LabelScanException(ScanFailure.unreadable),
      'daily_limit' => LabelScanException(
        ScanFailure.dailyLimit,
        limit: details is Map ? details['limit'] as int? : null,
      ),
      'image_too_large' => const LabelScanException(ScanFailure.imageTooLarge),
      _ => const LabelScanException(ScanFailure.unavailable),
    };
  }
}

/// For demo mode: always returns the same example after a short pause, so
/// the flow can be tried without a server. The app says it is an example.
class DemoLabelScanner implements LabelScanner {
  const DemoLabelScanner({this.delay = const Duration(milliseconds: 1200)});

  final Duration delay;

  @override
  Future<LabelScan> scan({
    required Uint8List front,
    Uint8List? back,
    required String language,
  }) async {
    await Future<void>.delayed(delay);
    return const LabelScan(
      name: 'Châteauneuf-du-Pape',
      producer: 'Domaine du Vieux Télégraphe',
      vintage: 2020,
      type: WineType.red,
      country: 'France',
      region: 'Rhône',
      grapes: ['Grenache', 'Syrah', 'Mourvèdre'],
      drinkFrom: 2026,
      drinkUntil: 2040,
      confidence: ScanConfidence.high,
      sommelier: SommelierInfo(
        tastingProfile:
            'Mörka bär, garrigue och lakrits. Kraftfull men med fin balans.',
        foodPairings: ['Lammstek', 'Viltgryta', 'Lagrad hårdost'],
        servingTemperature: '16–18 °C',
        decanting: 'Dekantera 1 timme när vinet är ungt.',
        producerInfo:
            'Familjen Brunier har drivit egendomen sedan 1898 på den '
            'steniga platån La Crau.',
      ),
    );
  }
}
