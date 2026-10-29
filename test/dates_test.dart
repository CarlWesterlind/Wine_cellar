import 'package:flutter_test/flutter_test.dart';
import 'package:wine_cellar/models/dates.dart';

void main() {
  test('dateOnly removes the time of day', () {
    expect(dateOnly(DateTime(2026, 3, 14, 23, 59, 59)), DateTime(2026, 3, 14));
  });

  test('toIsoDate pads months, days and years', () {
    expect(toIsoDate(DateTime(2026, 3, 4)), '2026-03-04');
    expect(toIsoDate(DateTime(999, 12, 31)), '0999-12-31');
  });

  test('parseIsoDate reads yyyy-MM-dd', () {
    expect(parseIsoDate('2026-03-04'), DateTime(2026, 3, 4));
    expect(parseIsoDate('2024-02-29'), DateTime(2024, 2, 29)); // Leap year.
  });

  test('parseIsoDate throws FormatException for anything else', () {
    for (final text in [
      '',
      'abc',
      '2026-3-4',
      '2026-03-04T10:00:00',
      '04-03-2026',
      '2026-13-01',
      '2026-02-30',
      '2025-02-29', // Not a leap year.
    ]) {
      expect(() => parseIsoDate(text), throwsFormatException, reason: text);
    }
  });

  test('toIsoDate and parseIsoDate round-trip', () {
    final date = DateTime(2026, 10, 29);
    expect(parseIsoDate(toIsoDate(date)), date);
  });

  test('clampDate keeps dates inside the range', () {
    final first = DateTime(1900), last = DateTime(2026, 10, 29);
    expect(clampDate(DateTime(1850), first, last), first);
    expect(clampDate(DateTime(2030), first, last), last);
    expect(clampDate(DateTime(2000, 5, 5), first, last), DateTime(2000, 5, 5));
  });
}
