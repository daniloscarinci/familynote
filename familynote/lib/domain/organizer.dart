import 'product_lexicon.dart';

export 'product_lexicon.dart' show ShoppingCategory;

/// Topics a free-form note can be filed under (fixed set, display order).
enum NoteCategory {
  saude('Saúde'),
  contas('Contas'),
  casa('Casa'),
  receitas('Receitas'),
  viagem('Viagem'),
  familia('Família'),
  lembretes('Lembretes'),
  outros('Outros');

  const NoteCategory(this.label);
  final String label;

  static NoteCategory? fromLabel(String? label) {
    for (final c in values) {
      if (c.label == label) return c;
    }
    return null;
  }
}

class ShoppingEntry {
  const ShoppingEntry(this.text, this.category);
  final String text;
  final ShoppingCategory category;

  @override
  String toString() => 'ShoppingEntry($text, ${category.label})';
}

class NoteDraft {
  const NoteDraft({required this.title, required this.body, required this.category});
  final String title;
  final String body;
  final NoteCategory category;
}

class OrganizedResult {
  const OrganizedResult({required this.shopping, this.note, this.duplicates = 0});
  final List<ShoppingEntry> shopping;
  final NoteDraft? note;

  /// How many repeated items were left out.
  final int duplicates;

  bool get isEmpty => shopping.isEmpty && note == null;
}

// ---------------------------------------------------------------- normalizing

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
};

/// Lowercase, no accents, only letters/digits separated by single spaces.
String normalize(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    b.write(_accents[ch] ?? ch);
  }
  return b.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

final _numeric = RegExp(r'^\d+[a-z]*$');
const _numberWords = {
  'um', 'uma', 'dois', 'duas', 'tres', 'quatro', 'cinco', 'seis', 'sete', 'oito', 'nove',
  'dez', 'meia', 'meio', 'varios', 'varias', 'algumas', 'alguns',
};
const _units = {
  'kg', 'kgs', 'g', 'gr', 'mg', 'l', 'lt', 'litro', 'litros', 'ml', 'un', 'und', 'unid',
  'unidade', 'unidades', 'pacote', 'pacotes', 'pct', 'caixa', 'caixas', 'cx', 'lata', 'latas',
  'garrafa', 'garrafas', 'duzia', 'duzias', 'dz', 'vidro', 'vidros', 'saco', 'sacos', 'pote',
  'potes', 'barra', 'barras', 'maco', 'macos', 'quilo', 'quilos', 'grama', 'gramas', 'x',
  'sache', 'saches', 'fardo', 'fardos', 'bandeja', 'bandejas',
};
const _verbs = {'comprar', 'pegar', 'trazer', 'buscar', 'preciso', 'precisa', 'falta', 'faltando'};
const _articles = {'o', 'a', 'os', 'as', 'um', 'uma', 'de', 'do', 'da', 'dos', 'das'};

/// Words of [text] that name the thing, without quantities, units or
/// "comprar". Used only for matching; display text is never changed.
List<String> _core(String text) {
  final t = normalize(text).split(' ').where((w) => w.isNotEmpty).toList();
  var i = 0;
  while (i < t.length && _verbs.contains(t[i])) {
    i++;
  }
  if (i < t.length && t[i] == 'de') i++;
  var dropped = false;
  while (i < t.length) {
    final w = t[i];
    if (_numeric.hasMatch(w) || _numberWords.contains(w)) {
      dropped = true;
      i++;
    } else if (w == 'duzia' || w == 'duzias') {
      dropped = true;
      i++;
    } else if (dropped && _units.contains(w)) {
      i++;
    } else if (dropped && (w == 'de' || w == 'do' || w == 'da')) {
      i++;
    } else {
      break;
    }
  }
  var end = t.length;
  while (end > i + 1 && (_numeric.hasMatch(t[end - 1]) || t[end - 1] == 'x')) {
    end--;
  }
  return t.sublist(i, end);
}

// -------------------------------------------------------------------- lexicon

final Map<String, ShoppingCategory> _lexicon = () {
  final m = <String, ShoppingCategory>{};
  for (final e in productWords.entries) {
    for (final w in e.value.split(RegExp(r'\s+'))) {
      if (w.isEmpty) continue;
      m[normalize(w)] = e.key;
    }
  }
  return m;
}();

/// Number of distinct product words and phrases known to the organizer.
int get lexiconSize => _lexicon.length;

List<String> _singulars(String w) {
  final c = <String>[];
  if (w.length < 3) return c;
  if (w.endsWith('oes') || w.endsWith('aes')) c.add('${w.substring(0, w.length - 3)}ao');
  if (w.endsWith('ais')) c.add('${w.substring(0, w.length - 3)}al');
  if (w.endsWith('eis')) c.add('${w.substring(0, w.length - 3)}el');
  if (w.endsWith('ns')) c.add('${w.substring(0, w.length - 2)}m');
  if (w.endsWith('es')) c.add(w.substring(0, w.length - 2));
  if (w.endsWith('s')) c.add(w.substring(0, w.length - 1));
  return c;
}

/// Returns the lexicon spelling of [phrase] (singular), or null.
String? _known(String phrase) {
  if (_lexicon.containsKey(phrase)) return phrase;
  final parts = phrase.split(' ');
  for (final s in _singulars(parts.last)) {
    final p = [...parts.sublist(0, parts.length - 1), s].join(' ');
    if (_lexicon.containsKey(p)) return p;
  }
  return null;
}

ShoppingCategory? _lookup(List<String> tokens) {
  var t = tokens;
  while (t.isNotEmpty && _articles.contains(t.first)) {
    t = t.sublist(1);
  }
  for (final n in [3, 2, 1]) {
    if (t.length < n) continue;
    final k = _known(t.take(n).join(' '));
    if (k != null) return _lexicon[k];
  }
  return null;
}

/// Aisle of a shopping item text; [ShoppingCategory.outros] when unknown.
ShoppingCategory categoryOfItem(String text) =>
    _lookup(_core(text)) ?? ShoppingCategory.outros;

/// Name used to compare items: accents, case, quantities and plurals ignored.
String shoppingKey(String text) => _core(text).map((w) => _known(w) ?? w).join(' ');

// ------------------------------------------------------------------- parsing

final _bullet = RegExp(r'^\s*(?:[-–—•*·▪●◦]+\s*|\d+\s*[.)]\s+)');

String _stripBullet(String s) {
  var out = s.trim();
  while (_bullet.hasMatch(out)) {
    final next = out.replaceFirst(_bullet, '').trim();
    if (next == out) break;
    out = next;
  }
  return out;
}

final _digit = RegExp(r'\d');

/// Splits on ';' and on commas (but not decimal commas such as "1,5").
List<String> _split(String line) {
  final parts = <String>[];
  final cur = StringBuffer();
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    final isDecimal = ch == ',' &&
        i > 0 &&
        i < line.length - 1 &&
        _digit.hasMatch(line[i - 1]) &&
        _digit.hasMatch(line[i + 1]);
    if ((ch == ',' && !isDecimal) || ch == ';') {
      parts.add(cur.toString());
      cur.clear();
    } else {
      cur.write(ch);
    }
  }
  parts.add(cur.toString());
  return parts;
}

const _headerWords = {'compras', 'compra', 'mercado', 'supermercado', 'lista', 'feira'};

bool _isHeaderText(String s) {
  final words = normalize(s).split(' ').where((w) => w.isNotEmpty).toList();
  return words.isNotEmpty && words.length <= 4 && words.any(_headerWords.contains);
}

bool _shoppingEntry(String text) {
  final core = _core(text);
  return core.isNotEmpty && core.length <= 4 && _lookup(core) != null;
}

/// Sorts free text into shopping items and one note. Pure and deterministic.
///
/// With [forceShopping] every entry is a shopping item. Items already in
/// [existing] are skipped (counted in [OrganizedResult.duplicates]).
OrganizedResult organize(
  String input, {
  bool forceShopping = false,
  Iterable<String> existing = const [],
  DateTime? now,
}) {
  final seen = <String>{...existing.map(shoppingKey)};
  final shopping = <ShoppingEntry>[];
  final noteLines = <String>[];
  var dups = 0;
  var listMode = false;

  void addItem(String text) {
    final key = shoppingKey(text);
    if (key.isEmpty) return;
    if (!seen.add(key)) {
      dups++;
      return;
    }
    shopping.add(ShoppingEntry(text, categoryOfItem(text)));
  }

  for (final raw in input.split(RegExp(r'\r?\n'))) {
    var line = _stripBullet(raw);
    if (line.isEmpty) {
      listMode = false;
      continue;
    }
    final colon = line.indexOf(':');
    if (colon >= 0 && _isHeaderText(line.substring(0, colon))) {
      listMode = true;
      line = line.substring(colon + 1).trim();
      if (line.isEmpty) continue;
    } else if (colon < 0 && _isHeaderText(line) && !forceShopping) {
      listMode = true;
      continue;
    } else if (line.endsWith(':')) {
      listMode = false;
      noteLines.add(line);
      continue;
    }

    final parts = _split(line).map(_stripBullet).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) continue;
    if (listMode || forceShopping) {
      for (final p in parts) {
        // A long sentence with no product word ends the list: it is a note.
        final core = _core(p);
        if (!forceShopping && core.length >= 5 && _lookup(core) == null) {
          listMode = false;
          noteLines.add(p);
        } else {
          addItem(p);
        }
      }
      continue;
    }
    final flags = parts.map(_shoppingEntry).toList();
    if (!flags.contains(true)) {
      noteLines.add(line);
      continue;
    }
    for (var i = 0; i < parts.length; i++) {
      if (flags[i]) {
        addItem(parts[i]);
      } else {
        noteLines.add(parts[i]);
      }
    }
  }

  final order = ShoppingCategory.values;
  final sortKey = {for (final e in shopping) e: shoppingKey(e.text)};
  shopping.sort((a, b) {
    final c = order.indexOf(a.category).compareTo(order.indexOf(b.category));
    return c != 0 ? c : sortKey[a]!.compareTo(sortKey[b]!);
  });

  NoteDraft? note;
  if (noteLines.isNotEmpty) {
    final body = noteLines.join('\n');
    note = NoteDraft(
      title: _title(noteLines.first, now ?? DateTime.now()),
      body: body,
      category: categoryOfNote(body),
    );
  }
  return OrganizedResult(shopping: shopping, note: note, duplicates: dups);
}

String _title(String firstLine, DateTime now) {
  final t = firstLine.trim();
  if (t.isEmpty) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Anotação de ${two(now.day)}/${two(now.month)}';
  }
  return t.length <= 40 ? t : t.substring(0, 40).trimRight();
}

// ----------------------------------------------------------------- note kinds

const _noteKeywords = <NoteCategory, List<String>>{
  NoteCategory.saude: [
    'medico', 'medica', 'consulta', 'exame', 'remedio', 'dentista', 'vacina', 'farmacia',
    'hospital', 'pressao', 'febre', 'cardiologista', 'fisioterapia', 'dermatologista',
    'oftalmologista', 'clinica', 'injecao', 'comprimido', 'dor',
  ],
  NoteCategory.contas: [
    'conta', 'pagar', 'boleto', 'vencimento', 'luz', 'agua', 'aluguel', 'condominio',
    'internet', 'telefone', 'fatura', 'cartao', 'imposto', 'iptu', 'ipva', 'parcela',
    'banco', 'pix', 'mensalidade', 'gas',
  ],
  NoteCategory.casa: [
    'reforma', 'consertar', 'conserto', 'encanador', 'eletricista', 'limpeza', 'pintar',
    'pintura', 'pedreiro', 'vazamento', 'torneira', 'telhado', 'jardim', 'faxina', 'mudanca',
    'movel', 'obra',
  ],
  NoteCategory.receitas: [
    'receita', 'ingrediente', 'modo de preparo', 'preparo', 'assar', 'xicara', 'colher',
  ],
  NoteCategory.viagem: [
    'viagem', 'viajar', 'passagem', 'hotel', 'mala', 'passaporte', 'voo', 'aeroporto',
    'reserva', 'hospedagem', 'roteiro', 'ferias', 'praia', 'rodoviaria',
  ],
  NoteCategory.familia: [
    'aniversario', 'festa', 'escola', 'filho', 'filha', 'neto', 'neta', 'casamento',
    'batizado', 'formatura', 'reuniao', 'almoco', 'jantar', 'natal', 'presente', 'visita',
    'parabens',
  ],
  NoteCategory.lembretes: ['lembrar', 'lembrete', 'esquecer', 'lembre'],
};

bool _hasKeyword(String normalized, List<String> tokens, String kw) {
  if (kw.contains(' ')) return normalized.contains(kw);
  return tokens.any((t) =>
      t == kw || t == '${kw}s' || t == '${kw}es' || (kw.length >= 6 && t.startsWith(kw)));
}

/// Picks the topic with most keyword hits; ties go to the earlier topic.
NoteCategory categoryOfNote(String text) {
  final n = normalize(text);
  final tokens = n.split(' ');
  var best = NoteCategory.outros;
  var bestScore = 0;
  for (final e in _noteKeywords.entries) {
    final score = e.value.where((k) => _hasKeyword(n, tokens, k)).length;
    if (score > bestScore) {
      best = e.key;
      bestScore = score;
    }
  }
  return best;
}
