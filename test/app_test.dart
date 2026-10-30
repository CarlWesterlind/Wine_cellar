import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wine_cellar/app.dart';
import 'package:wine_cellar/data/cellar_services.dart';
import 'package:wine_cellar/models/wine.dart';

import 'failing_wine_repository.dart';
import 'helpers.dart';

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

    await drinkABottle(tester);
    expect(find.text('2 bottles'), findsOneWidget);
  });

  group('errors are shown as friendly messages, never as raw exceptions', () {
    late FailingWineRepository repository;

    setUp(() {
      repository = FailingWineRepository([Wine(name: 'Barolo', quantity: 3)]);
    });

    testWidgets('loading fails, then works after "Try again"', (tester) async {
      repository.error = StateError('secret internal detail');
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );

      expect(
        find.text('Something unexpected went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('secret internal detail'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);

      repository.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Barolo'), findsOneWidget);
    });

    testWidgets('a failed delete keeps the wine and shows a message', (
      tester,
    ) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'sv'}),
        repository: repository,
      );
      await tester.tap(find.text('Barolo'));
      await tester.pumpAndSettle();

      repository.error = StateError('offline');
      await tester.tap(find.byTooltip('Ta bort vin'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Ta bort'));
      await tester.pumpAndSettle();

      expect(find.text('Något oväntat gick fel. Försök igen.'), findsOneWidget);
      // Still on the detail screen, and the wine still exists.
      expect(find.text('3 flaskor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed "drink a bottle" keeps the count', (tester) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await tester.tap(find.text('Barolo'));
      await tester.pumpAndSettle();

      repository.error = StateError('offline');
      await drinkABottle(tester);

      expect(
        find.text('Something unexpected went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('3 bottles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed save keeps the form open with a message', (
      tester,
    ) async {
      await pumpApp(
        tester,
        await settingsWith({'locale': 'en'}),
        repository: repository,
      );
      await tester.tap(find.text('Add wine'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Chablis',
      );

      repository.error = StateError('offline');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Something unexpected went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Add wine'), findsOneWidget); // Form is still open.
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the form rejects invalid input before saving', (tester) async {
    await pumpApp(tester, await settingsWith({'locale': 'en'}));
    await tester.tap(find.text('Add wine'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'X');
    await tester.enterText(find.widgetWithText(TextFormField, 'Bottles'), '-2');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Vintage'),
      'abc',
    );
    final drinkFrom = find.widgetWithText(TextFormField, 'Drink from (year)');
    await tester.scrollUntilVisible(
      drinkFrom,
      200,
      scrollable: find
          .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
          .first,
    );
    await tester.enterText(drinkFrom, '2030');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Drink until (year)'),
      '2020',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid number'), findsOneWidget);
    expect(find.text('Enter a valid year'), findsOneWidget);
    expect(find.text('Must not be earlier than "drink from"'), findsOneWidget);
    expect(find.text('Add wine'), findsOneWidget); // Not saved.
  });

  testWidgets(
    'changing theme or language keeps the same services (and photos)',
    (tester) async {
      final settings = await settingsWith({'locale': 'en'});
      var created = 0;
      await tester.pumpWidget(
        WineCellarApp(
          settings: settings,
          createServices: () {
            created++;
            return CellarServices.demo();
          },
        ),
      );
      await tester.pumpAndSettle();

      await settings.setThemeMode(ThemeMode.dark);
      await settings.setLocale(const Locale('sv'));
      await tester.pumpAndSettle();

      expect(find.text('Vinkällaren'), findsOneWidget);
      expect(created, 1);
    },
  );
}
