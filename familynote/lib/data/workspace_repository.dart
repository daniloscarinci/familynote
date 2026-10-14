import '../domain/models.dart';

abstract class WorkspaceRepository {
  String? get currentUserId;
  Future<String?> currentWorkspaceId();
  Future<String> createWorkspace(String name);
  Future<String> createInvitation(String workspaceId, String role);
  Future<String> acceptInvitation(String token);
  Future<List<Member>> members(String workspaceId);
}

class FakeWorkspaceRepository implements WorkspaceRepository {
  FakeWorkspaceRepository({this.userId = 'me', this.workspaceId, List<Member>? members})
      : _members = members ?? [];

  final String userId;
  String? workspaceId;
  final List<Member> _members;
  final invitations = <String>[];
  final createdNames = <String>[];
  Object? createError;
  Object? currentError;

  @override
  String? get currentUserId => userId;

  @override
  Future<String?> currentWorkspaceId() async {
    if (currentError != null) throw currentError!;
    return workspaceId;
  }

  @override
  Future<String> createWorkspace(String name) async {
    if (createError != null) throw createError!;
    createdNames.add(name);
    workspaceId = 'ws1';
    _members.add(Member(userId: userId, displayName: '', role: Role.admin));
    return workspaceId!;
  }

  @override
  Future<String> createInvitation(String workspaceId, String role) async {
    final t = 'TOKEN${invitations.length}';
    invitations.add(t);
    return t;
  }

  @override
  Future<String> acceptInvitation(String token) async {
    if (!invitations.contains(token)) throw Exception('invalid or expired invitation');
    workspaceId = 'ws1';
    return workspaceId!;
  }

  @override
  Future<List<Member>> members(String workspaceId) async => List.of(_members);
}
