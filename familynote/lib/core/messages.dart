import 'dart:async';

const offlineMessage = 'Sem internet. Sua nota está guardada e será enviada depois.';
const _generic = 'Algo deu errado. Tente de novo.';

/// The single place where exceptions become plain-language pt-BR sentences.
/// [fallback] is used when the cause is not recognised.
String friendlyMessage(Object error, {String? fallback}) {
  final text = error.toString().toLowerCase();
  if (error is TimeoutException ||
      text.contains('failed host lookup') ||
      text.contains('clientexception') ||
      text.contains('failed to fetch') ||
      text.contains('xmlhttprequest') ||
      text.contains('socketexception') ||
      text.contains('network')) {
    return offlineMessage;
  }
  if (text.contains('invalid or expired invitation')) {
    return 'Este convite não vale mais. Peça um novo link para quem convidou você.';
  }
  if (text.contains('rate limit') || text.contains('rate_limit') || text.contains('429')) {
    return 'Muitas tentativas. Espere um pouco e tente de novo.';
  }
  if (text.contains('anonymous')) {
    return 'Não foi possível entrar com este link. Peça ajuda a quem convidou você.';
  }
  if (text.contains('not authenticated') || text.contains('jwt')) {
    return 'Sua sessão terminou. Entre de novo.';
  }
  return fallback ?? _generic;
}
