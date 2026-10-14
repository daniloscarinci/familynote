import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../data/workspace_repository.dart';
import '../domain/repositories.dart';

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => throw UnimplementedError('override authRepositoryProvider'));
final workspaceRepositoryProvider = Provider<WorkspaceRepository>(
    (ref) => throw UnimplementedError('override workspaceRepositoryProvider'));
final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => throw UnimplementedError('override profileRepositoryProvider'));
final noteRepositoryFactoryProvider = Provider<NoteRepository Function(String workspaceId)>(
    (ref) => throw UnimplementedError('override noteRepositoryFactoryProvider'));
final listRepositoryFactoryProvider = Provider<ListRepository Function(String workspaceId)>(
    (ref) => throw UnimplementedError('override listRepositoryFactoryProvider'));

/// Address where the app is hosted; invite links are built from it ('' if unknown).
final appUrlProvider = Provider<String>((ref) => '');

/// Opens an address outside the app (WhatsApp). Overridden with a fake in tests.
typedef UrlOpener = Future<bool> Function(Uri uri);
final urlOpenerProvider = Provider<UrlOpener>(
    (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

/// Invitation token found in the address the app was opened from, if any.
final initialJoinTokenProvider = Provider<String?>((ref) => null);

class JoinTokenNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(initialJoinTokenProvider);

  void clear() => state = null;
}

final joinTokenProvider = NotifierProvider<JoinTokenNotifier, String?>(JoinTokenNotifier.new);

const textScaleKey = 'text_scale';

/// Initial text scale loaded from shared_preferences in main(); 1.0 in tests.
final initialTextScaleProvider = Provider<double>((ref) => 1.0);

class TextScaleNotifier extends Notifier<double> {
  @override
  double build() => ref.watch(initialTextScaleProvider);

  Future<void> set(double v) async {
    state = v;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(textScaleKey, v);
    } catch (_) {
      // Persistence is best effort; the in-memory value still applies.
    }
  }
}

final textScaleProvider = NotifierProvider<TextScaleNotifier, double>(TextScaleNotifier.new);
