import 'package:supabase_flutter/supabase_flutter.dart';

enum SignUpResult { signedIn, confirmEmail }

abstract interface class AuthService {
  bool get isSignedIn;
  String? get email;

  /// Emits whenever the user signs in or out.
  Stream<bool> get signedInChanges;

  Future<void> signIn(String email, String password);
  Future<SignUpResult> signUp(String email, String password);
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._auth);

  final GoTrueClient _auth;

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  String? get email => _auth.currentUser?.email;

  @override
  Stream<bool> get signedInChanges =>
      _auth.onAuthStateChange.map((state) => state.session != null);

  @override
  Future<void> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  @override
  Future<SignUpResult> signUp(String email, String password) async {
    final response = await _auth.signUp(email: email, password: password);
    // Without a session the project requires the email to be confirmed first.
    return response.session == null
        ? SignUpResult.confirmEmail
        : SignUpResult.signedIn;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
