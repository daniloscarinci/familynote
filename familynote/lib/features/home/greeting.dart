/// "Bom dia, Maria" by time of day; "Olá" when the name is not known.
String greeting(DateTime now, String? name) {
  final first = (name ?? '').trim().split(RegExp(r'\s+')).first;
  if (first.isEmpty) return 'Olá';
  final h = now.hour;
  final hello = h >= 5 && h < 12 ? 'Bom dia' : (h >= 12 && h < 18 ? 'Boa tarde' : 'Boa noite');
  return '$hello, $first';
}
