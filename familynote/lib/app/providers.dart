import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_repository.dart';
import '../data/workspace_repository.dart';
import '../domain/repositories.dart';

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => throw UnimplementedError('override authRepositoryProvider'));
final workspaceRepositoryProvider = Provider<WorkspaceRepository>(
    (ref) => throw UnimplementedError('override workspaceRepositoryProvider'));
final noteRepositoryFactoryProvider = Provider<NoteRepository Function(String workspaceId)>(
    (ref) => throw UnimplementedError('override noteRepositoryFactoryProvider'));
final listRepositoryFactoryProvider = Provider<ListRepository Function(String workspaceId)>(
    (ref) => throw UnimplementedError('override listRepositoryFactoryProvider'));

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
