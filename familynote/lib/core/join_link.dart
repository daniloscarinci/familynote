/// Reads and builds family invitation links such as `https://host/#/join/<token>`.
class JoinLinkParser {
  static final _valid = RegExp(r'^[A-Za-z0-9_-]+$');

  /// Returns the invitation token found in [uri], or null.
  static String? fromUri(Uri uri) {
    final fromFragment = _fromFragment(uri.fragment);
    if (fromFragment != null) return fromFragment;
    return _clean(uri.queryParameters['join']);
  }

  static String? _fromFragment(String fragment) {
    if (fragment.isEmpty) return null;
    final m = RegExp(r'^/?join/([^/?#]*)').firstMatch(fragment);
    if (m != null) {
      try {
        return _clean(Uri.decodeComponent(m.group(1)!));
      } catch (_) {
        return null;
      }
    }
    final q = fragment.indexOf('?');
    if (q >= 0) {
      try {
        return _clean(Uri.splitQueryString(fragment.substring(q + 1))['join']);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String? _clean(String? t) {
    final s = t?.trim();
    if (s == null || s.isEmpty || !_valid.hasMatch(s)) return null;
    return s;
  }
}

String _trimSlash(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;

String buildInviteLink(String appUrl, String token) => '${_trimSlash(appUrl)}/#/join/$token';

/// APP_URL define if set, otherwise the address the page was opened from
/// (without query, hash or index.html). Empty when unknown.
String resolveAppUrl({required String define, required Uri base}) {
  if (define.trim().isNotEmpty) return _trimSlash(define.trim());
  if (base.scheme != 'http' && base.scheme != 'https') return '';
  var path = base.path;
  if (path.endsWith('index.html')) path = path.substring(0, path.length - 'index.html'.length);
  final origin = Uri(scheme: base.scheme, host: base.host, port: base.hasPort ? base.port : null);
  return _trimSlash('$origin$path');
}
