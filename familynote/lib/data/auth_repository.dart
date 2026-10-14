import 'dart:async';

abstract class AuthRepository {
  /// Emits the current state on listen, then every change.
  Stream<bool> get signedIn;
  Future<void> sendCode(String email);
  Future<void> verifyCode(String email, String code);
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
