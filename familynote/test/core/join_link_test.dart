import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/join_link.dart';

void main() {
  const token = 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4';

  group('JoinLinkParser', () {
    test('reads token from hash route', () {
      expect(JoinLinkParser.fromUri(Uri.parse('https://app.exemplo.com/#/join/$token')), token);
    });
    test('reads token from hash route with trailing slash', () {
      expect(JoinLinkParser.fromUri(Uri.parse('https://app.exemplo.com/#/join/$token/')), token);
    });
    test('reads token from query parameter', () {
      expect(JoinLinkParser.fromUri(Uri.parse('https://app.exemplo.com/?join=$token')), token);
    });
    test('reads token from query parameter inside the fragment', () {
      expect(JoinLinkParser.fromUri(Uri.parse('https://app.exemplo.com/#/?join=$token')), token);
    });
    test('returns null when there is no token', () {
      expect(JoinLinkParser.fromUri(Uri.parse('https://app.exemplo.com/')), isNull);
      expect(JoinLinkParser.fromUri(Uri.parse('https://app.exemplo.com/#/join/')), isNull);
      expect(JoinLinkParser.fromUri(Uri.parse('https://app.exemplo.com/?join=')), isNull);
    });
    test('rejects tokens with unexpected characters', () {
      expect(JoinLinkParser.fromUri(Uri.parse('https://x.com/#/join/a%20b%3Cscript%3E')), isNull);
    });
  });

  group('links', () {
    test('buildInviteLink joins app url and token', () {
      expect(buildInviteLink('https://app.exemplo.com', token),
          'https://app.exemplo.com/#/join/$token');
      expect(buildInviteLink('https://app.exemplo.com/', token),
          'https://app.exemplo.com/#/join/$token');
    });

    test('resolveAppUrl prefers the define', () {
      expect(
          resolveAppUrl(
              define: 'https://familia.exemplo.com/', base: Uri.parse('http://localhost:5000/')),
          'https://familia.exemplo.com');
    });
    test('resolveAppUrl falls back to the page address, without hash or query', () {
      expect(
          resolveAppUrl(
              define: '',
              base: Uri.parse('https://x.github.io/familynote/index.html?join=abc#/join/abc')),
          'https://x.github.io/familynote');
      expect(resolveAppUrl(define: '', base: Uri.parse('http://localhost:5000/#/')),
          'http://localhost:5000');
    });
  });
}
