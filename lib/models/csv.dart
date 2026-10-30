/// Writes rows as CSV text that Excel, Numbers and Google Sheets can open.
library;

/// Nordic Excel expects `;`, since `,` is the decimal separator there.
const csvSeparator = ';';

String toCsv(List<List<String>> rows, {String separator = csvSeparator}) => rows
    .map((row) => row.map((cell) => _cell(cell, separator)).join(separator))
    .join('\r\n');

String _cell(String value, String separator) {
  // Text starting with these is run as a formula by spreadsheet apps, so a
  // wine named "=HYPERLINK(...)" would become a link. A leading ' stops it.
  if (value.startsWith(RegExp(r'[=+\-@\t\r]'))) value = "'$value";
  final needsQuotes =
      value.contains(separator) ||
      value.contains(RegExp('["\r\n]')) ||
      value != value.trim();
  return needsQuotes ? '"${value.replaceAll('"', '""')}"' : value;
}
