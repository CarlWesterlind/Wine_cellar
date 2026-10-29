import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthException,
        AuthRetryableFetchException,
        FunctionsFetchException,
        PostgrestException;

import '../data/label_scanner.dart';
import '../l10n/app_localizations.dart';

/// Turns any error into a short message for the user, in their language.
/// The technical details and stack trace are never shown; [logError]
/// writes them to the debug console for developers instead.
String errorMessage(AppLocalizations l10n, Object error) {
  if (error is AuthRetryableFetchException ||
      error is http.ClientException ||
      error is FunctionsFetchException) {
    return l10n.errorNetwork;
  }
  if (error is LabelScanException) {
    return switch (error.reason) {
      ScanFailure.notWineLabel => l10n.errorNotWineLabel,
      ScanFailure.unreadable => l10n.errorUnreadable,
      ScanFailure.dailyLimit => l10n.errorDailyLimit(error.limit ?? 50),
      ScanFailure.imageTooLarge => l10n.errorImageTooLarge,
      ScanFailure.unsupportedImage => l10n.errorUnsupportedImage,
      ScanFailure.unavailable => l10n.errorAiUnavailable,
    };
  }
  if (error is AuthException) {
    return switch (error.code) {
      'invalid_credentials' => l10n.errorInvalidLogin,
      'email_not_confirmed' => l10n.errorEmailNotConfirmed,
      'user_already_exists' || 'email_exists' => l10n.errorUserExists,
      'weak_password' => l10n.errorWeakPassword,
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' => l10n.errorTooManyAttempts,
      _ => l10n.errorUnknown,
    };
  }
  if (error is PostgrestException) return l10n.errorServer;
  if (error is ArgumentError || error is FormatException) {
    return l10n.errorInvalidData;
  }
  return l10n.errorUnknown;
}

/// Writes the full error to the debug console. Not visible to users.
void logError(Object error, [StackTrace? stack]) {
  debugPrint('Error: $error');
  if (stack != null) debugPrint('$stack');
}

/// Runs [action]. If it fails, logs the error, shows a friendly message at
/// the bottom of the screen and returns false.
Future<bool> runOrShowError(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error, stack) {
    logError(error, stack);
    if (context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(l10n, error))));
    }
    return false;
  }
}
