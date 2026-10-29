/// Reading numbers typed by the user. Blank or invalid text gives null.
library;

int? parseWholeNumber(String? text) => int.tryParse(text?.trim() ?? '');

/// Accepts both "12.50" and "12,50", since Nordic keyboards use a comma.
double? parseDecimal(String? text) =>
    double.tryParse((text?.trim() ?? '').replaceAll(',', '.'));
