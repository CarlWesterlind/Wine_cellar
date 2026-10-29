import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException, PostgrestException;
import 'package:wine_cellar/errors/error_messages.dart';
import 'package:wine_cellar/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  String message(Object error) => errorMessage(l10n, error);

  test('network problems ask the user to check their connection', () {
    expect(
      message(http.ClientException('Failed host lookup')),
      l10n.errorNetwork,
    );
    expect(message(AuthRetryableFetchException()), l10n.errorNetwork);
  });

  test('login errors get specific messages', () {
    expect(
      message(const AuthException('x', code: 'invalid_credentials')),
      l10n.errorInvalidLogin,
    );
    expect(
      message(const AuthException('x', code: 'email_not_confirmed')),
      l10n.errorEmailNotConfirmed,
    );
    expect(
      message(const AuthException('x', code: 'user_already_exists')),
      l10n.errorUserExists,
    );
    expect(
      message(const AuthException('x', code: 'weak_password')),
      l10n.errorWeakPassword,
    );
    expect(
      message(const AuthException('x', code: 'over_request_rate_limit')),
      l10n.errorTooManyAttempts,
    );
    expect(message(const AuthException('x')), l10n.errorUnknown);
  });

  test('database errors become a server message', () {
    expect(
      message(const PostgrestException(message: 'permission denied')),
      l10n.errorServer,
    );
  });

  test('invalid data errors become an invalid data message', () {
    expect(message(ArgumentError.value(-1, 'quantity')), l10n.errorInvalidData);
    expect(message(const FormatException('bad row')), l10n.errorInvalidData);
  });

  test('anything else gets a general message without technical details', () {
    final text = message(StateError('internal detail'));
    expect(text, l10n.errorUnknown);
    expect(text, isNot(contains('internal detail')));
  });
}
