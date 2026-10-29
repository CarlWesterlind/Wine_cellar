import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/data/label_scanner.dart';
import 'package:wine_cellar/data/photo_storage.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/label_scan.dart';
import 'package:wine_cellar/models/sommelier_info.dart';
import 'package:wine_cellar/models/wine.dart';
import 'package:wine_cellar/widgets/sommelier_card.dart';
import 'package:wine_cellar/widgets/wine_photo.dart';

import 'failing_wine_repository.dart';
import 'helpers.dart';

const barolo = LabelScan(
  name: 'Barolo Cannubi',
  producer: 'Paolo Scavino',
  vintage: 2019,
  type: WineType.red,
  country: 'Italia',
  region: 'Piemonte',
  grapes: ['Nebbiolo'],
  drinkFrom: 2027,
  drinkUntil: 2040,
  confidence: ScanConfidence.high,
  sommelier: SommelierInfo(
    tastingProfile: 'Körsbär, ros och tjära.',
    foodPairings: ['Tryffelrisotto', 'Viltgryta'],
    servingTemperature: '17–18 °C',
    decanting: 'En till två timmar.',
    producerInfo: 'Familjeägd producent.',
  ),
);

/// Returns [result], or throws [error]; records what it was asked. With
/// [gate] it waits until the test completes it.
class FakeScanner implements LabelScanner {
  FakeScanner({this.result = barolo, this.error, this.gate});

  final LabelScan result;
  final Object? error;
  final Completer<void>? gate;
  final calls = <({Uint8List front, Uint8List? back, String language})>[];

  @override
  Future<LabelScan> scan({
    required Uint8List front,
    Uint8List? back,
    required String language,
  }) async {
    calls.add((front: front, back: back, language: language));
    await gate?.future;
    if (error case final error?) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
    return result;
  }
}

final backJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 9, 9]);

void main() {
  late InMemoryWineRepository repository;
  late InMemoryPhotoStorage photos;

  setUp(() {
    repository = InMemoryWineRepository();
    photos = InMemoryPhotoStorage();
  });

  Future<void> openNewWineForm(
    WidgetTester tester, {
    LabelScanner? scanner,
    List<Uint8List?> pickedPhotos = const [],
    bool isDemo = false,
    String locale = 'en',
  }) async {
    // Starts with one wine so the list (and its add button) is shown.
    await repository.add(Wine(name: 'Rioja'));
    await pumpApp(
      tester,
      await settingsWith({'locale': locale}),
      repository: repository,
      photos: photos,
      scanner: scanner ?? FakeScanner(),
      pickPhoto: fakePicker(pickedPhotos),
      isDemo: isDemo,
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> takePhotoAndSkipBack(WidgetTester tester) async {
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(find.text('Add the back label?'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  }

  testWidgets('a photo fills in the form, and the wine is saved with it', (
    tester,
  ) async {
    final scanner = FakeScanner();
    await openNewWineForm(tester, scanner: scanner, pickedPhotos: [fakeJpeg]);
    expect(find.text('Photograph the label'), findsOneWidget);

    await takePhotoAndSkipBack(tester);

    expect(scanner.calls.single.front, fakeJpeg);
    expect(scanner.calls.single.back, isNull);
    expect(scanner.calls.single.language, 'en');
    expect(fieldText(tester, 'Name'), 'Barolo Cannubi');
    expect(fieldText(tester, 'Producer'), 'Paolo Scavino');
    expect(fieldText(tester, 'Vintage'), '2019');
    expect(fieldText(tester, 'Grapes'), 'Nebbiolo');
    expect(fieldText(tester, 'Drink from (year)'), '2027');
    expect(find.text('Suggested by AI'), findsWidgets);
    // 8 text fields + type + sommelier.
    expect(
      find.text('AI filled in 10 fields. Check them before saving.'),
      findsOneWidget,
    );
    expect(find.byType(SommelierCard), findsOneWidget);
    expect(find.byType(PhotoBytes), findsOneWidget);

    await tapSave(tester);

    final saved = (await repository.fetchAll()).firstWhere(
      (w) => w.name == 'Barolo Cannubi',
    );
    expect(saved.region, 'Piemonte');
    expect(saved.drinkUntil, 2040);
    expect(saved.sommelier?.foodPairings, ['Tryffelrisotto', 'Viltgryta']);
    expect(saved.photoPath, isNotNull);
    expect(await photos.load(saved.photoPath!), fakeJpeg);
    // The reminder to check the AI values is gone with the form.
    expect(find.textContaining('AI filled in'), findsNothing);
    // The list shows the photo instead of the colored badge.
    expect(find.byType(WinePhoto), findsOneWidget);
  });

  testWidgets('the back label is sent along when added', (tester) async {
    final scanner = FakeScanner();
    await openNewWineForm(
      tester,
      scanner: scanner,
      pickedPhotos: [fakeJpeg, backJpeg],
    );
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add back label'));
    await tester.pumpAndSettle();

    expect(scanner.calls.single.front, fakeJpeg);
    expect(scanner.calls.single.back, backJpeg);
  });

  testWidgets('what the user already typed is kept', (tester) async {
    await openNewWineForm(tester, pickedPhotos: [fakeJpeg]);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Min egen Barolo',
    );
    await takePhotoAndSkipBack(tester);

    expect(fieldText(tester, 'Name'), 'Min egen Barolo');
    expect(fieldText(tester, 'Producer'), 'Paolo Scavino');
  });

  testWidgets('changing an AI value removes its AI hint', (tester) async {
    await openNewWineForm(tester, pickedPhotos: [fakeJpeg]);
    await takePhotoAndSkipBack(tester);
    final hints = tester.widgetList(find.text('Suggested by AI')).length;

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Producer'),
      'Scavino',
    );
    await tester.pump();
    expect(find.text('Suggested by AI'), findsNWidgets(hints - 1));
  });

  testWidgets('the AI suggestions can be removed before saving', (
    tester,
  ) async {
    await openNewWineForm(tester, pickedPhotos: [fakeJpeg]);
    await takePhotoAndSkipBack(tester);
    await scrollFormTo(tester, find.byTooltip('Remove AI suggestions'));
    await tester.tap(find.byTooltip('Remove AI suggestions'));
    await tester.pump();
    expect(find.byType(SommelierCard), findsNothing);

    await tapSave(tester);
    final saved = (await repository.fetchAll()).last;
    expect(saved.sommelier, isNull);
  });

  testWidgets('shows progress while reading and blocks saving', (tester) async {
    final gate = Completer<void>();
    await openNewWineForm(
      tester,
      scanner: FakeScanner(gate: gate),
      pickedPhotos: [fakeJpeg],
    );
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reading the label…'), findsOneWidget);
    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(saveButton.onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Reading the label…'), findsNothing);
    expect(fieldText(tester, 'Name'), 'Barolo Cannubi');
  });

  testWidgets('cancelling the camera changes nothing', (tester) async {
    final scanner = FakeScanner();
    await openNewWineForm(tester, scanner: scanner, pickedPhotos: [null]);
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();

    expect(find.text('Add the back label?'), findsNothing);
    expect(scanner.calls, isEmpty);
    expect(find.text('Photograph the label'), findsOneWidget);
  });

  for (final (description, error, message) in [
    (
      'the daily limit',
      const LabelScanException(ScanFailure.dailyLimit, limit: 50),
      "You've reached the limit of 50 scans per day. Try again tomorrow, "
          'or fill in the details yourself.',
    ),
    (
      'a photo that is not a wine label',
      const LabelScanException(ScanFailure.notWineLabel),
      "That doesn't look like a wine label. Try another photo.",
    ),
    (
      'an unreadable label',
      const LabelScanException(ScanFailure.unreadable),
      "The label couldn't be read. Try a sharper photo with good light.",
    ),
    (
      'an unexpected error',
      StateError('boom'),
      'Something unexpected went wrong. Please try again.',
    ),
  ]) {
    testWidgets('$description gives a clear message and keeps the photo', (
      tester,
    ) async {
      await openNewWineForm(
        tester,
        scanner: FakeScanner(error: error),
        pickedPhotos: [fakeJpeg],
      );
      await takePhotoAndSkipBack(tester);

      expect(find.text(message), findsOneWidget);
      expect(find.byType(PhotoBytes), findsOneWidget);
      expect(fieldText(tester, 'Name'), isEmpty);
      expect(tester.takeException(), isNull);

      // The wine can still be filled in by hand and saved with the photo.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Handskrivet',
      );
      await tapSave(tester);
      final saved = (await repository.fetchAll()).last;
      expect(saved.name, 'Handskrivet');
      expect(saved.photoPath, isNotNull);
    });
  }

  testWidgets('a camera error is shown instead of crashing', (tester) async {
    await repository.add(Wine(name: 'Rioja'));
    await pumpApp(
      tester,
      await settingsWith({'locale': 'en'}),
      repository: repository,
      photos: photos,
      scanner: FakeScanner(),
      pickPhoto: (_) async => throw StateError('camera_access_denied'),
    );
    await tester.tap(find.text('Add wine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();

    expect(
      find.text('Something unexpected went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo mode says the result is only an example', (tester) async {
    await openNewWineForm(tester, pickedPhotos: [fakeJpeg], isDemo: true);
    await takePhotoAndSkipBack(tester);
    expect(
      find.text('Demo mode: this is an example result, not a real AI reading.'),
      findsOneWidget,
    );
  });

  testWidgets('a low-confidence scan asks for extra care', (tester) async {
    await openNewWineForm(
      tester,
      scanner: FakeScanner(
        result: const LabelScan(name: 'Vin', confidence: ScanConfidence.low),
      ),
      pickedPhotos: [fakeJpeg],
    );
    await takePhotoAndSkipBack(tester);
    expect(
      find.text(
        "The AI isn't sure about this label. Check the details carefully.",
      ),
      findsOneWidget,
    );
    expect(
      find.text('AI filled in 1 field. Check it before saving.'),
      findsOneWidget,
    );
  });

  testWidgets('scanning describes the wine in the app language', (
    tester,
  ) async {
    final scanner = FakeScanner();
    await openNewWineForm(
      tester,
      scanner: scanner,
      pickedPhotos: [fakeJpeg],
      locale: 'nb',
    );
    await tester.tap(find.text('Ta bilde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hopp over'));
    await tester.pumpAndSettle();
    expect(scanner.calls.single.language, 'nb');
  });

  testWidgets('if saving fails, the uploaded photo is cleaned up', (
    tester,
  ) async {
    final failing = FailingWineRepository([Wine(name: 'Rioja')]);
    await pumpApp(
      tester,
      await settingsWith({'locale': 'en'}),
      repository: failing,
      photos: photos,
      scanner: FakeScanner(),
      pickPhoto: fakePicker([fakeJpeg]),
    );
    await tester.tap(find.text('Add wine'));
    await tester.pumpAndSettle();
    await takePhotoAndSkipBack(tester);

    failing.error = StateError('offline');
    await tapSave(tester);

    expect(find.text('Add wine'), findsOneWidget); // Still on the form.
    expect(photos.count, 0);
  });

  group('an existing wine with a photo', () {
    late String oldPath;

    Future<void> openEditForm(
      WidgetTester tester, {
      List<Uint8List?> pickedPhotos = const [],
    }) async {
      oldPath = await photos.save(fakeJpeg);
      await repository.add(
        Wine(
          name: 'Barolo',
          photoPath: oldPath,
          sommelier: const SommelierInfo(tastingProfile: 'Ros och tjära.'),
        ),
      );
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
        photos: photos,
        scanner: FakeScanner(),
        pickPhoto: fakePicker(pickedPhotos),
      );
      await tester.tap(find.text('Barolo'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the photo and sommelier notes on its page', (
      tester,
    ) async {
      await openEditForm(tester);
      expect(find.byType(WinePhoto), findsOneWidget);
      await scrollTo(tester, find.text('Ros och tjära.'));
      expect(
        find.text('Suggestions from AI. They can contain mistakes.'),
        findsOneWidget,
      );
    });

    testWidgets('removing the photo deletes it from storage', (tester) async {
      await openEditForm(tester);
      await tester.tap(find.byTooltip('Edit wine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove photo'));
      await tester.pump();
      expect(find.text('Photograph the label'), findsOneWidget);
      await tapSave(tester);

      expect((await repository.fetchAll()).single.photoPath, isNull);
      expect(photos.count, 0);
    });

    testWidgets('replacing the photo deletes the old one', (tester) async {
      await openEditForm(tester, pickedPhotos: [backJpeg]);
      await tester.tap(find.byTooltip('Edit wine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tapSave(tester);

      final newPath = (await repository.fetchAll()).single.photoPath!;
      expect(newPath, isNot(oldPath));
      expect(await photos.load(newPath), backJpeg);
      expect(photos.count, 1);
    });

    testWidgets('editing without touching the photo keeps it', (tester) async {
      await openEditForm(tester);
      await tester.tap(find.byTooltip('Edit wine'));
      await tester.pumpAndSettle();
      await tapSave(tester);

      final wine = (await repository.fetchAll()).single;
      expect(wine.photoPath, oldPath);
      expect(wine.sommelier?.tastingProfile, 'Ros och tjära.');
      expect(photos.count, 1);
    });

    testWidgets('deleting the wine deletes its photo', (tester) async {
      await openEditForm(tester);
      await tester.tap(find.byTooltip('Delete wine'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await repository.fetchAll(), isEmpty);
      expect(photos.count, 0);
    });

    testWidgets('the label can be read again from the stored photo', (
      tester,
    ) async {
      await openEditForm(tester);
      await tester.tap(find.byTooltip('Edit wine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read label again'));
      await tester.pumpAndSettle();

      // The name stays, the empty fields are filled.
      expect(fieldText(tester, 'Name'), 'Barolo');
      expect(fieldText(tester, 'Producer'), 'Paolo Scavino');
    });
  });

  testWidgets('the form with a photo meets the accessibility guidelines', (
    tester,
  ) async {
    await openNewWineForm(tester, pickedPhotos: [fakeJpeg]);
    await takePhotoAndSkipBack(tester);
    await tester.pumpAndSettle(const Duration(seconds: 5)); // Snackbar gone.

    await expectMeetsGuidelines(tester);
  });
}
