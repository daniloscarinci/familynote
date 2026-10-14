/// The signed-in person's own profile (the name other family members see).
abstract class ProfileRepository {
  /// Empty string when no name was saved yet.
  Future<String> displayName();
  Future<void> setDisplayName(String name);
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.name = ''});
  String name;
  Object? error;

  @override
  Future<String> displayName() async => name;

  @override
  Future<void> setDisplayName(String value) async {
    if (error != null) throw error!;
    name = value.trim();
  }
}
