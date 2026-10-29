import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wine_cellar/app.dart';
import 'package:wine_cellar/data/wine_repository.dart';
import 'package:wine_cellar/models/wine.dart';
import 'package:wine_cellar/state/app_settings.dart';

Future<AppSettings> settingsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return AppSettings(await SharedPreferences.getInstance());
}

Future<void> pumpApp(
  WidgetTester tester,
  AppSettings settings, {
  WineRepository? repository,
  bool settle = true,
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
  if (settle) await tester.pumpAndSettle();
}
