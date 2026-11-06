/// Text matching for the lexicon: ignoring case, accents and punctuation,
/// and allowing small typos.
library;

const _plain = {
  'a': 'àáâãäåāăą',
  'c': 'çćčĉ',
  'd': 'ďđ',
  'e': 'èéêëēėęěẽ',
  'g': 'ğ',
  'i': 'ìíîïīįı',
  'l': 'łľ',
  'n': 'ñńň',
  'o': 'òóôõöōőø',
  'r': 'ŕř',
  's': 'śšşș',
  't': 'ťţț',
  'u': 'ùúûüūůűų',
  'y': 'ýÿ',
  'z': 'źżž',
};

const _ligatures = {'ß': 'ss', 'æ': 'ae', 'œ': 'oe'};

final Map<String, String> _replacements = {
  for (final MapEntry(key: plain, value: accented) in _plain.entries)
    for (final char in accented.split('')) char: plain,
  ..._ligatures,
};

final _notLetterOrDigit = RegExp(r'[^a-z0-9]+');

/// [text] in lower case without accents, with everything that is not a
/// letter or digit turned into single spaces: "Grüner-Veltliner" becomes
/// "gruner veltliner".
String normalizeForSearch(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(_replacements[char] ?? char);
  }
  return buffer.toString().replaceAll(_notLetterOrDigit, ' ').trim();
}

/// The number of single-letter edits (insert, delete, replace, or swap two
/// neighbours) that turn [a] into [b]. Stops counting above [max] and then
/// returns `max + 1`.
int editDistance(String a, String b, int max) {
  if ((a.length - b.length).abs() > max) return max + 1;
  // Three rows: two back (for swaps), previous and current.
  var twoBack = List<int>.filled(b.length + 1, 0);
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    var rowMin = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var value = [
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
      if (i > 1 &&
          j > 1 &&
          a[i - 1] == b[j - 2] &&
          a[i - 2] == b[j - 1] &&
          twoBack[j - 2] + 1 < value) {
        value = twoBack[j - 2] + 1;
      }
      current[j] = value;
      if (value < rowMin) rowMin = value;
    }
    if (rowMin > max) return max + 1;
    twoBack = previous;
    previous = current;
  }
  final result = previous[b.length];
  return result > max ? max + 1 : result;
}
