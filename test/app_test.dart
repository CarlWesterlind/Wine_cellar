import 'package:flutter/material.dart';
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

Future<void> pumpApp(WidgetTester tester, LanguageSettings settings) async {
  await tester.pumpWidget(
    WineCellarApp(
      settings: settings,
      createRepository: () => InMemoryWineRepository(const [
        Wine(name: 'Barolo', producer: 'Scavino', quantity: 3, price: 650),
      ]),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('resolveLocale', () {
    const supported = [Locale('da'), Locale('en'), Locale('nb'), Locale('sv')];

    test('uses a supported device language', () {
      expect(
        resolveLocale(const Locale('sv', 'SE'), supported),
        const Locale('sv'),
      );
      expect(resolveLocale(const Locale('da'), supported), const Locale('da'));
    });

    test('maps Norwegian variants to Bokmål', () {
      expect(resolveLocale(const Locale('no'), supported), const Locale('nb'));
      expect(resolveLocale(const Locale('nn'), supported), const Locale('nb'));
    });

    test('falls back to English', () {
      expect(resolveLocale(const Locale('fr'), supported), const Locale('en'));
      expect(resolveLocale(null, supported), const Locale('en'));
    });
  });

  testWidgets('shows the cellar in the saved language', (tester) async {
    await pumpApp(tester, await settingsWith({'locale': 'sv'}));

    expect(find.text('Vinkällaren'), findsOneWidget);
    expect(find.text('Barolo'), findsOneWidget);
    expect(find.textContaining('3 flaskor'), findsOneWidget);
  });

  testWidgets('switching language updates the app and is remembered', (
    tester,
  ) async {
    final settings = await settingsWith({'locale': 'en'});
    await pumpApp(tester, settings);
    expect(find.text('Wine Cellar'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dansk'));
    await tester.pumpAndSettle();

    expect(find.text('Indstillinger'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'da');
  });

  testWidgets('adds a wine through the form', (tester) async {
    await pumpApp(tester, await settingsWith({'locale': 'en'}));

    await tester.tap(find.text('Add wine'));
    await tester.pumpAndSettle();

    // Saving without a name shows a validation error.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Chablis',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Bottles'), '6');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Chablis'), findsOneWidget);
    expect(find.textContaining('9 bottles'), findsOneWidget);
  });

  testWidgets('drinking a bottle lowers the count', (tester) async {
    await pumpApp(tester, await settingsWith({'locale': 'en'}));

    await tester.tap(find.text('Barolo'));
    await tester.pumpAndSettle();
    expect(find.text('3 bottles'), findsOneWidget);

    await tester.tap(find.text('Drink a bottle'));
    await tester.pumpAndSettle();
    expect(find.text('2 bottles'), findsOneWidget);
  });
}
