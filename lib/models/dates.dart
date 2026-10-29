/// Helpers for calendar dates without a time of day, stored as `yyyy-MM-dd`.
library;

/// [value] with the time of day removed.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Formats [date] as `yyyy-MM-dd`, the format of a Postgres `date` column.
String toIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Reads a `yyyy-MM-dd` date. Throws [FormatException] for anything else.
DateTime parseIsoDate(String text) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (match == null) throw FormatException('Not a yyyy-MM-dd date', text);
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final date = DateTime(year, month, day);
  // DateTime silently rolls over invalid dates like 2026-02-30.
  if (date.month != month || date.day != day) {
    throw FormatException('No such date', text);
  }
  return date;
}

/// [date] moved inside the range [first]–[last] if it is outside it.
DateTime clampDate(DateTime date, DateTime first, DateTime last) {
  if (date.isBefore(first)) return first;
  if (date.isAfter(last)) return last;
  return date;
}
