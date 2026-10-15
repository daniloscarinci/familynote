import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/messages.dart';
import 'package:familynote/data/auth_repository.dart';

void main() {
  test('offline errors say there is no internet', () {
    expect(friendlyMessage(const SocketException('Failed host lookup')), offlineMessage);
    expect(friendlyMessage(TimeoutException('x')), offlineMessage);
    expect(friendlyMessage(Exception('ClientException: Failed to fetch')), offlineMessage);
  });

  test('offline message is the agreed sentence', () {
    expect(offlineMessage, 'Sem internet. Sua nota está guardada e será enviada depois.');
  });

  test('password sign-in errors are plain pt-BR', () {
    expect(friendlyMessage(Exception('AuthApiException(message: Invalid login credentials)')),
        'E-mail ou senha incorretos.');
    expect(friendlyMessage(Exception('weak_password: Password should be at least 6 characters')),
        'A senha precisa ter pelo menos 6 caracteres.');
    expect(friendlyMessage(Exception('User already registered')),
        'Esse e-mail já tem uma conta. Toque em Entrar.');
    expect(friendlyMessage(Exception('over_email_send_rate_limit')),
        'Muitas tentativas. Espere um pouco e tente de novo.');
    expect(friendlyMessage(const ConfirmationRequired()),
        'Enviamos um e-mail para confirmar. Abra o link e depois entre aqui.');
    expect(friendlyMessage(Exception('Failed to fetch')), offlineMessage);
  });

  test('invalid invitation', () {
    expect(friendlyMessage(Exception('invalid or expired invitation')), contains('convite'));
  });

  test('unknown errors use the fallback or a generic sentence', () {
    expect(friendlyMessage(Exception('boom'), fallback: 'Não foi possível salvar.'),
        'Não foi possível salvar.');
    expect(friendlyMessage(Exception('boom')), 'Algo deu errado. Tente de novo.');
  });

  test('no technical words leak', () {
    final out = friendlyMessage(Exception('PostgrestException 42501 row-level security'));
    for (final w in ['Postgrest', 'Exception', 'security', '42501']) {
      expect(out.contains(w), isFalse);
    }
  });

  test('rate limits and disabled anonymous sign-in', () {
    expect(friendlyMessage(Exception('over_request_rate_limit')), contains('Muitas tentativas'));
    expect(friendlyMessage(Exception('Anonymous sign-ins are disabled')), contains('link'));
  });
}
