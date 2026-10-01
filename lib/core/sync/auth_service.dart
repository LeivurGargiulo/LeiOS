import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthUser {
  const AuthUser({required this.id, required this.email});
  final String id;
  final String email;
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin seam over Supabase Auth so UI/providers can be tested with a fake.
abstract class AuthService {
  AuthUser? get currentUser;
  Stream<AuthUser?> get changes;
  Future<void> signIn(String email, String password);

  /// Returns true when the account is ready to use, false when email confirmation is required.
  Future<bool> signUp(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String newPassword);
  Future<void> signOut();
}

/// Readable messages for the common auth failures (spec §3).
String friendlyAuthError(Object e) {
  if (e is AuthException) return e.message;
  final msg = e is sb.AuthException ? e.message : e.toString();
  final lower = msg.toLowerCase();
  if (lower.contains('invalid login') || lower.contains('invalid_credentials')) {
    return 'Incorrect email or password.';
  }
  if (lower.contains('not confirmed') || lower.contains('email_not_confirmed')) {
    return 'Please confirm your email first. Check your inbox.';
  }
  if (lower.contains('already registered') || lower.contains('user_already_exists')) {
    return 'An account with this email already exists.';
  }
  if (lower.contains('password') && lower.contains('characters')) {
    return 'Password is too short.';
  }
  if (lower.contains('socket') || lower.contains('network') || lower.contains('failed host lookup') ||
      lower.contains('clientexception') || lower.contains('connection')) {
    return "You're offline. Connect to the internet to continue.";
  }
  return msg;
}

class SupabaseAuthService implements AuthService {
  sb.GoTrueClient get _auth => sb.Supabase.instance.client.auth;

  AuthUser? _map(sb.User? u) => u == null ? null : AuthUser(id: u.id, email: u.email ?? '');

  @override
  AuthUser? get currentUser => _map(_auth.currentSession?.user ?? _auth.currentUser);

  @override
  Stream<AuthUser?> get changes => _auth.onAuthStateChange.map((s) => _map(s.session?.user));

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  @override
  Future<bool> signUp(String email, String password) async {
    try {
      final r = await _auth.signUp(email: email.trim(), password: password);
      return r.session != null;
    } catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(sb.UserAttributes(password: newPassword));
    } catch (e) {
      throw AuthException(friendlyAuthError(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// In-memory implementation for tests and the integration (mock login) flow.
class FakeAuthService implements AuthService {
  FakeAuthService({AuthUser? initial}) : _user = initial;
  AuthUser? _user;
  final _ctrl = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _user;
  @override
  Stream<AuthUser?> get changes => _ctrl.stream;

  @override
  Future<void> signIn(String email, String password) async {
    if (password != 'password') throw AuthException('Incorrect email or password.');
    _user = AuthUser(id: '00000000-0000-0000-0000-0000000000a1', email: email);
    _ctrl.add(_user);
  }

  @override
  Future<bool> signUp(String email, String password) async {
    await signIn(email, 'password');
    return true;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> updatePassword(String newPassword) async {}
  @override
  Future<void> signOut() async {
    _user = null;
    _ctrl.add(null);
  }
}
