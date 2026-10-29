import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionsClient;
import 'package:wine_cellar/data/images.dart';
import 'package:wine_cellar/data/label_scanner.dart';
import 'package:wine_cellar/models/label_scan.dart';
import 'package:wine_cellar/models/sommelier_info.dart';
import 'package:wine_cellar/models/wine.dart';

const scanJson = {
  'is_wine_label': true,
  'confidence': 'high',
  'name': 'Barolo Cannubi',
  'producer': 'Paolo Scavino',
  'vintage': 2019,
  'type': 'red',
  'country': 'Italia',
  'region': 'Piemonte',
  'grapes': ['Nebbiolo'],
  'drink_from': 2027,
  'drink_until': 2040,
  'sommelier': {
    'tasting_profile': 'Körsbär och ros.',
    'food_pairings': ['Tryffelrisotto'],
    'serving_temperature': '17 °C',
    'decanting': 'En timme.',
  },
  'producer_info': 'Familjeägt.',
};

void main() {
  group('SommelierInfo', () {
    test('round-trips through the database format', () {
      const info = SommelierInfo(
        tastingProfile: 'Mineraliskt',
        foodPairings: ['Ostron', 'Sushi'],
        servingTemperature: '10 °C',
        decanting: 'Nej',
        producerInfo: 'Gammal familjegård.',
      );
      final copy = SommelierInfo.fromMap(info.toMap());
      expect(copy.toMap(), info.toMap());
    });

    test('blank text becomes null and empty food pairings are dropped', () {
      final info = SommelierInfo.fromMap({
        'tasting_profile': '  ',
        'food_pairings': ['Ost', ' ', ''],
        'serving_temperature': null,
      });
      expect(info.tastingProfile, isNull);
      expect(info.foodPairings, ['Ost']);
      expect(info.isEmpty, isFalse);
      expect(SommelierInfo.fromMap({}).isEmpty, isTrue);
    });
  });

  group('LabelScan.fromMap', () {
    test('reads every field', () {
      final scan = LabelScan.fromMap(scanJson);
      expect(scan.name, 'Barolo Cannubi');
      expect(scan.vintage, 2019);
      expect(scan.type, WineType.red);
      expect(scan.grapes, ['Nebbiolo']);
      expect(scan.drinkFrom, 2027);
      expect(scan.confidence, ScanConfidence.high);
      expect(scan.sommelier?.foodPairings, ['Tryffelrisotto']);
      expect(scan.sommelier?.producerInfo, 'Familjeägt.');
    });

    test('producer info alone still gives sommelier info', () {
      final scan = LabelScan.fromMap({
        ...scanJson,
        'sommelier': null,
        'producer_info': 'Känd producent.',
      });
      expect(scan.sommelier?.producerInfo, 'Känd producent.');
      expect(scan.sommelier?.tastingProfile, isNull);
    });

    test('no sommelier info at all gives null', () {
      final scan = LabelScan.fromMap({
        ...scanJson,
        'sommelier': null,
        'producer_info': null,
      });
      expect(scan.sommelier, isNull);
    });

    test('unknown type and confidence are handled', () {
      final scan = LabelScan.fromMap({
        ...scanJson,
        'type': 'orange',
        'confidence': '??',
      });
      expect(scan.type, isNull);
      expect(scan.confidence, ScanConfidence.low);
    });

    test('values of the wrong type throw FormatException', () {
      expect(
        () => LabelScan.fromMap({...scanJson, 'vintage': 'nittonhundra'}),
        throwsFormatException,
      );
      expect(
        () => LabelScan.fromMap({...scanJson, 'sommelier': 'text'}),
        throwsFormatException,
      );
    });
  });

  test('Wine keeps its photo and sommelier info through the database', () {
    final wine = Wine(
      name: 'Barolo',
      photoPath: 'user/abc.jpg',
      sommelier: const SommelierInfo(tastingProfile: 'Ros'),
    );
    final copy = Wine.fromMap({...wine.toMap(), 'id': '1'});
    expect(copy.photoPath, 'user/abc.jpg');
    expect(copy.sommelier?.tastingProfile, 'Ros');
    expect(copy.withQuantity(2).photoPath, 'user/abc.jpg');
  });

  group('imageMediaType', () {
    test('recognises JPEG, PNG and WebP', () {
      expect(
        imageMediaType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])),
        'image/jpeg',
      );
      expect(
        imageMediaType(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D])),
        'image/png',
      );
      expect(
        imageMediaType(
          Uint8List.fromList([
            ...ascii.encode('RIFF'),
            0,
            0,
            0,
            0,
            ...ascii.encode('WEBP'),
          ]),
        ),
        'image/webp',
      );
    });

    test('rejects other formats and too-short data', () {
      expect(
        imageMediaType(Uint8List.fromList(ascii.encode('GIF89a'))),
        isNull,
      );
      expect(imageMediaType(Uint8List.fromList([0xFF])), isNull);
      expect(imageMediaType(Uint8List(0)), isNull);
      // HEIC, which some phones use.
      expect(
        imageMediaType(
          Uint8List.fromList([0, 0, 0, 0x18, ...ascii.encode('ftypheic')]),
        ),
        isNull,
      );
    });
  });

  group('SupabaseLabelScanner', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2]);
    final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2]);

    SupabaseLabelScanner scannerAnswering(
      int status,
      Object body, {
      void Function(Map<String, dynamic> request)? onRequest,
    }) {
      final client = MockClient((request) async {
        onRequest?.call(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        );
      });
      return SupabaseLabelScanner(
        FunctionsClient(
          'https://example.supabase.co/functions/v1',
          {},
          httpClient: client,
        ),
      );
    }

    test('sends the photos as base64 with type and language', () async {
      late Map<String, dynamic> sent;
      final scanner = scannerAnswering(200, {
        'scan': scanJson,
      }, onRequest: (request) => sent = request);
      final scan = await scanner.scan(front: jpeg, back: jpeg, language: 'da');

      expect(scan.name, 'Barolo Cannubi');
      expect(sent['front'], base64Encode(jpeg));
      expect(sent['back'], base64Encode(jpeg));
      expect(sent['mediaType'], 'image/jpeg');
      expect(sent['language'], 'da');
    });

    test('leaves out the back photo when there is none', () async {
      late Map<String, dynamic> sent;
      await scannerAnswering(
        200,
        {'scan': scanJson},
        onRequest: (request) => sent = request,
      ).scan(front: png, language: 'sv');
      expect(sent.containsKey('back'), isFalse);
      expect(sent['mediaType'], 'image/png');
    });

    test(
      'refuses unsupported or mixed image types without calling the server',
      () async {
        var called = false;
        final scanner = scannerAnswering(200, {
          'scan': scanJson,
        }, onRequest: (_) => called = true);
        final gif = Uint8List.fromList(ascii.encode('GIF89a'));

        for (final (front, back) in [(gif, null), (jpeg, png)]) {
          await expectLater(
            scanner.scan(front: front, back: back, language: 'sv'),
            throwsA(isA<UnsupportedImageException>()),
          );
        }
        expect(called, isFalse);
      },
    );

    for (final (status, code, reason) in [
      (422, 'not_wine_label', ScanFailure.notWineLabel),
      (422, 'unreadable', ScanFailure.unreadable),
      (413, 'image_too_large', ScanFailure.imageTooLarge),
      (502, 'ai_unavailable', ScanFailure.unavailable),
      (401, 'unauthorized', ScanFailure.unavailable),
      (500, 'something new', ScanFailure.unavailable),
    ]) {
      test('maps "$code" to $reason', () async {
        await expectLater(
          scannerAnswering(status, {
            'error': code,
          }).scan(front: jpeg, language: 'sv'),
          throwsA(
            isA<LabelScanException>().having((e) => e.reason, 'reason', reason),
          ),
        );
      });
    }

    test('passes on the daily limit', () async {
      await expectLater(
        scannerAnswering(429, {
          'error': 'daily_limit',
          'limit': 50,
        }).scan(front: jpeg, language: 'sv'),
        throwsA(
          isA<LabelScanException>()
              .having((e) => e.reason, 'reason', ScanFailure.dailyLimit)
              .having((e) => e.limit, 'limit', 50),
        ),
      );
    });

    test('an unexpected answer is reported, not crashed on', () async {
      for (final body in [
        <String, dynamic>{},
        {'scan': 'text'},
        {
          'scan': {'vintage': 'x'},
        },
      ]) {
        await expectLater(
          scannerAnswering(200, body).scan(front: jpeg, language: 'sv'),
          throwsA(
            isA<LabelScanException>().having(
              (e) => e.reason,
              'reason',
              ScanFailure.unavailable,
            ),
          ),
        );
      }
    });
  });
}
