import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wine_cellar/app.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/wine.dart';
import 'package:wine_cellar/state/language_settings.dart';

Future<LanguageSettings> settingsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return LanguageSettings(await SharedPreferences.getInstance());
}

Future<void> pumpApp(
  WidgetTester tester,
  LanguageSettings settings, {
  WineRepository? repository,
}) async {
  await tester.pumpWidget(
    WineCellarApp(
      settings: settings,
      createRepository: () =>
          repository ??
          InMemoryWineRepository([
            Wine(name: 'Barolo', producer: 'Scavino', quantity: 3, price: 650),
          ]),
    ),
  );
  await tester.pumpAndSettle();
}
