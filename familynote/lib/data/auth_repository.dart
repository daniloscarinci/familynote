import 'dart:async';

/// Thrown by sign-up when the account exists but must be confirmed by e-mail.
class ConfirmationRequired implements Exception {
  const ConfirmationRequired();
  @override
  String toString() => 'ConfirmationRequired';
}

abstract class AuthRepository {
  /// Emits the current state on listen, then every change.
  Stream<bool> get signedIn;
  Future<void> sendCode(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> signInWithPassword(String email, String password);
  /// Throws [ConfirmationRequired] when the e-mail must be confirmed first.
  Future<void> signUpWithPassword(String email, String password);
  /// Creates a real, individual account bound to this device (invite links).
  Future<void> signInAnonymously();
  Future<void> signOut();
}

/// In-memory auth for tests. The only valid code is [validCode].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({bool signedIn = false}) : _value = signedIn;

  static const validCode = '123456';
  bool _value;
  final _c = StreamController<bool>.broadcast();
  final sentTo = <String>[];

  @override
  Stream<bool> get signedIn async* {
    yield _value;
    yield* _c.stream;
  }

  void _set(bool v) {
    _value = v;
    _c.add(v);
  }

  @override
  Future<void> sendCode(String email) async => sentTo.add(email);

  @override
  Future<void> verifyCode(String email, String code) async {
    if (code != validCode) throw Exception('invalid code');
    _set(true);
  }

  final accounts = <String, String>{};
  bool requireConfirmation = false;

  @override
  Future<void> signInWithPassword(String email, String password) async {
    if (accounts[email] != password) throw Exception('Invalid login credentials');
    _set(true);
  }

  @override
  Future<void> signUpWithPassword(String email, String password) async {
    if (password.length < 6) throw Exception('Password should be at least 6 characters');
    if (accounts.containsKey(email)) throw Exception('User already registered');
    accounts[email] = password;
    if (requireConfirmation) throw const ConfirmationRequired();
    _set(true);
  }

  int anonymousSignIns = 0;
  Object? anonymousError;

  @override
  Future<void> signInAnonymously() async {
    if (anonymousError != null) throw anonymousError!;
    anonymousSignIns++;
    _set(true);
  }

  @override
  Future<void> signOut() async => _set(false);
}
