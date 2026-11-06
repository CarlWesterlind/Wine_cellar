import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wine_cellar/lexicon/lexicon_store.dart';

/// A minimal lexicon file with one grape named [grape].
String lexiconFile({
  required int version,
  String grape = 'Syrah',
  int format = 1,
}) => jsonEncode({
  'format': format,
  'version': version,
  'countries': [],
  'places': [],
  'grapes': [
    {'id': grape.toLowerCase(), 'name': grape, 'color': 'red'},
  ],
  'blends': [],
  'classifications': [],
  'sweetness': [],
});

void main() {
  late SharedPreferences prefs;
  var now = DateTime(2026, 11, 6, 12);
  late Map<String, String?> published;
  late List<String> fetched;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 11, 6, 12);
    published = {};
    fetched = [];
  });

  LexiconStore store({String? bundled}) => LexiconStore(
    loadBundled: () async => bundled ?? lexiconFile(version: 1),
    fetch: (file) async {
      fetched.add(file);
      return published[file];
    },
    prefs: prefs,
    clock: () => now,
  );

  String? firstGrape(LexiconStore s) => s.lexicon?.grapes.first.name;

  void publish(int version, {String grape = 'Merlot', int format = 1}) {
    published['version.json'] = jsonEncode({
      'format': format,
      'version': version,
    });
    published['lexicon.json'] = lexiconFile(
      version: version,
      grape: grape,
      format: format,
    );
  }

  test('loads the lexicon shipped with the app', () async {
    final s = store();
    expect(s.lexicon, isNull);
    await s.load();
    expect(firstGrape(s), 'Syrah');
    expect(s.search!.grapes('syr').single.text, 'Syrah');
  });

  test(
    'a newer saved lexicon wins over the shipped one; an older does not',
    () async {
      await prefs.setString(
        'lexicon_json',
        lexiconFile(version: 5, grape: 'Merlot'),
      );
      final s = store(bundled: lexiconFile(version: 3));
      await s.load();
      expect(firstGrape(s), 'Merlot');

      await prefs.setString(
        'lexicon_json',
        lexiconFile(version: 2, grape: 'Merlot'),
      );
      final t = store(bundled: lexiconFile(version: 3));
      await t.load();
      expect(firstGrape(t), 'Syrah');
    },
  );

  test('downloads a newer published lexicon and keeps it', () async {
    publish(2);
    final s = store();
    await s.load();
    var notified = false;
    s.addListener(() => notified = true);

    await s.checkForUpdate();
    expect(firstGrape(s), 'Merlot');
    expect(notified, isTrue);

    // Used from the device next time, without downloading.
    final next = store();
    await next.load();
    expect(firstGrape(next), 'Merlot');
  });

  test('downloads only the small version file when nothing is new', () async {
    publish(1);
    final s = store();
    await s.load();
    await s.checkForUpdate();
    expect(fetched, ['version.json']);
    expect(firstGrape(s), 'Syrah');
  });

  test('checks at most once a day', () async {
    final s = store();
    await s.load();
    await s.checkForUpdate();
    now = now.add(const Duration(hours: 23));
    await s.checkForUpdate();
    expect(fetched, hasLength(1));

    now = now.add(const Duration(hours: 2));
    await s.checkForUpdate();
    expect(fetched, hasLength(2));
  });

  test('a broken or unknown download leaves the lexicon in use', () async {
    for (final setup in <void Function()>[
      () => published = {'version.json': 'not json'},
      () => published = {
        'version.json': jsonEncode({'format': 1, 'version': 9}),
        'lexicon.json': '{"broken": true}',
      },
      () => publish(9, format: 2),
    ]) {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      setup();
      final s = store();
      await s.load();
      await s.checkForUpdate();
      expect(firstGrape(s), 'Syrah');
      expect(prefs.getString('lexicon_json'), isNull);
    }
  });

  test('a failing download leaves the lexicon in use', () async {
    final s = LexiconStore(
      loadBundled: () async => lexiconFile(version: 1),
      fetch: (_) async => throw StateError('offline'),
      prefs: prefs,
      clock: () => now,
    );
    await s.load();
    await expectLater(s.checkForUpdate(), completes);
    expect(firstGrape(s), 'Syrah');
  });
}
