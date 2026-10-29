import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wine_cellar/app.dart';
import 'package:wine_cellar/data/cellar_services.dart';
import 'package:wine_cellar/data/label_scanner.dart';
import 'package:wine_cellar/data/photo_picker.dart';
import 'package:wine_cellar/data/photo_storage.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/wine.dart';
import 'package:wine_cellar/state/app_settings.dart';

Future<AppSettings> settingsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return AppSettings(await SharedPreferences.getInstance());
}

/// The first bytes of a JPEG file, enough for [imageMediaType].
final fakeJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]);

/// Hands out [photos] one by one, then null as if the user cancelled.
PhotoPicker fakePicker(List<Uint8List?> photos) {
  final queue = [...photos];
  return (_) async => queue.isEmpty ? null : queue.removeAt(0);
}

Future<void> pumpApp(
  WidgetTester tester,
  AppSettings settings, {
  WineRepository? repository,
  PhotoStorage? photos,
  LabelScanner? scanner,
  PhotoPicker? pickPhoto,
  bool isDemo = false,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    WineCellarApp(
      settings: settings,
      createServices: () => CellarServices(
        wines:
            repository ??
            InMemoryWineRepository([
              Wine(
                name: 'Barolo',
                producer: 'Scavino',
                quantity: 3,
                price: 650,
              ),
            ]),
        photos: photos ?? InMemoryPhotoStorage(),
        scanner: scanner ?? const DemoLabelScanner(delay: Duration.zero),
        pickPhoto: pickPhoto ?? fakePicker([]),
        isDemo: isDemo,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// Checks Flutter's contrast, label and tap-target guidelines on the screen
/// as it is now.
Future<void> expectMeetsGuidelines(WidgetTester tester) async {
  final semantics = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  semantics.dispose();
}

/// Scrolls the innermost scrolling area until [finder] is on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);

/// Scrolls the form until [finder] is on screen.
Future<void> scrollFormTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
          .first,
    );

/// The text in the form field labelled [label].
String fieldText(WidgetTester tester, String label) => tester
    .widget<TextFormField>(find.widgetWithText(TextFormField, label))
    .controller!
    .text;

Future<void> tapSave(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}
