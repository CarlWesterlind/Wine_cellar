import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../errors/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../widgets/motion_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _signingUp = false;
  var _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    final email = _email.text.trim();
    try {
      if (_signingUp) {
        final result = await widget.auth.signUp(email, _password.text);
        if (result == SignUpResult.confirmEmail && mounted) {
          setState(() {
            _signingUp = false;
            _message = l10n.confirmEmailSent;
          });
        }
      } else {
        await widget.auth.signIn(email, _password.text);
      }
    } catch (error, stack) {
      logError(error, stack);
      if (mounted) setState(() => _message = errorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FadeSlideIn(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.wine_bar,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration(labelText: l10n.email),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : l10n.invalidEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(labelText: l10n.password),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) => v != null && v.length >= 6
                          ? null
                          : l10n.passwordTooShort,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(_message!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(_signingUp ? l10n.signUp : l10n.signIn),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _signingUp = !_signingUp;
                              _message = null;
                            }),
                      child: Text(
                        _signingUp ? l10n.switchToSignIn : l10n.switchToSignUp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
