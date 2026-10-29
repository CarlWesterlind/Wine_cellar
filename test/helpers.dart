import 'dart:typed_data';

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
  bool demoScanner = false,
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
        demoScanner: demoScanner,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
