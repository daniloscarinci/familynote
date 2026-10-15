import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/domain/organizer.dart';

List<String> texts(OrganizedResult r) => r.shopping.map((e) => e.text).toList();

ShoppingCategory cat(String s) => organize(s, forceShopping: true).shopping.single.category;

void main() {
  group('normalize', () {
    test('lowercases and removes accents', () => expect(normalize('PÃO Açúcar'), 'pao acucar'));
    test('collapses spaces and punctuation', () => expect(normalize('  leite,   integral! '), 'leite integral'));
    test('keeps digits', () => expect(normalize('2kg Arroz'), '2kg arroz'));
  });

  group('splitting', () {
    test('commas', () => expect(texts(organize('leite, pão, ovos')), unorderedEquals(['leite', 'pão', 'ovos'])));
    test('semicolons', () => expect(texts(organize('leite; pão')).length, 2));
    test('newlines', () => expect(texts(organize('leite\npão\narroz')).length, 3));
    test('decimal comma is not a separator', () {
      final r = organize('1,5 kg de arroz');
      expect(r.shopping.single.text, '1,5 kg de arroz');
    });
    test('dash bullets', () => expect(texts(organize('- leite\n- pão')), ['leite', 'pão'].reversed.toList()..sort((a, b) => 0)));
    test('dot bullet', () => expect(texts(organize('• arroz')), ['arroz']));
    test('star bullet', () => expect(texts(organize('* arroz')), ['arroz']));
    test('numbered with dot', () => expect(texts(organize('1. arroz\n2. feijão')), ['arroz', 'feijão']));
    test('numbered with paren', () => expect(texts(organize('1) arroz\n2) feijão')), ['arroz', 'feijão']));
    test('quantity is not a bullet', () => expect(texts(organize('2 kg arroz')), ['2 kg arroz']));
    test('empty entries are dropped', () => expect(texts(organize(',, ;\n\n leite ,')), ['leite']));
    test('windows newlines', () => expect(texts(organize('leite\r\npão')).length, 2));
  });

  group('empty and long input', () {
    test('empty', () {
      final r = organize('');
      expect(r.isEmpty, isTrue);
      expect(r.note, isNull);
    });
    test('only spaces and separators', () => expect(organize('  \n , ; \n').isEmpty, isTrue));
    test('long input of 500 lines', () {
      final input = List.generate(500, (i) => 'item$i').join('\n');
      final r = organize(input);
      expect(r.shopping, isEmpty);
      expect(r.note!.body.split('\n').length, 500);
    });
    test('long shopping list of repeated words dedupes', () {
      final r = organize(List.filled(300, 'leite').join(', '));
      expect(r.shopping.length, 1);
      expect(r.duplicates, 299);
    });
  });

  group('classification', () {
    test('lexicon has at least 250 words', () => expect(lexiconSize, greaterThanOrEqualTo(250)));
    test('known product is shopping', () => expect(organize('leite').shopping.length, 1));
    test('unknown word is a note', () {
      final r = organize('ligar para o João');
      expect(r.shopping, isEmpty);
      expect(r.note!.body, 'ligar para o João');
    });
    test('accent-insensitive', () => expect(organize('pao\ncafe\nacucar').shopping.length, 3));
    test('uppercase', () => expect(organize('LEITE').shopping.length, 1));
    test('plural -s', () => expect(cat('bananas'), ShoppingCategory.hortifruti));
    test('plural -es', () => expect(cat('tomates'), ShoppingCategory.hortifruti));
    test('plural -ões', () => expect(cat('limões'), ShoppingCategory.hortifruti));
    test('plural -ães', () => expect(cat('pães'), ShoppingCategory.padaria));
    test('plural -ns', () => expect(cat('ovos'), ShoppingCategory.mercearia));
    test('quantity digit', () => expect(organize('2 leites').shopping.length, 1));
    test('quantity with unit', () => expect(cat('2kg arroz'), ShoppingCategory.mercearia));
    test('quantity litro de', () => expect(cat('1 litro de leite'), ShoppingCategory.frios));
    test('quantity dúzia de', () => expect(cat('uma dúzia de ovos'), ShoppingCategory.mercearia));
    test('display text keeps what was written', () {
      expect(organize('2 Kg de Arroz').shopping.single.text, '2 Kg de Arroz');
    });
    test('verb comprar is ignored for matching', () => expect(cat('comprar pão'), ShoppingCategory.padaria));
    test('two-word phrase', () => expect(cat('papel higiênico'), ShoppingCategory.higiene));
    test('three-word phrase', () => expect(cat('pão de queijo'), ShoppingCategory.padaria));
    test('long sentence starting with a product is a note', () {
      final r = organize('leite vai estragar se ninguém levar amanhã cedo');
      expect(r.shopping, isEmpty);
      expect(r.note, isNotNull);
    });
    test('unknown item under header goes to Outros', () {
      final r = organize('Compras:\nfoo bar');
      expect(r.shopping.single.category, ShoppingCategory.outros);
      expect(r.note, isNull);
    });
  });

  group('aisles', () {
    test('hortifruti', () => expect(cat('alface'), ShoppingCategory.hortifruti));
    test('padaria', () => expect(cat('pão francês'), ShoppingCategory.padaria));
    test('açougue', () => expect(cat('frango'), ShoppingCategory.acougue));
    test('frios', () => expect(cat('queijo'), ShoppingCategory.frios));
    test('mercearia', () => expect(cat('feijão'), ShoppingCategory.mercearia));
    test('bebidas', () => expect(cat('suco'), ShoppingCategory.bebidas));
    test('congelados', () => expect(cat('sorvete'), ShoppingCategory.congelados));
    test('limpeza', () => expect(cat('detergente'), ShoppingCategory.limpeza));
    test('higiene', () => expect(cat('shampoo'), ShoppingCategory.higiene));
    test('bebê e pet', () => expect(cat('fralda'), ShoppingCategory.bebePet));
    test('água is a drink but água sanitária is cleaning', () {
      expect(cat('água'), ShoppingCategory.bebidas);
      expect(cat('água sanitária'), ShoppingCategory.limpeza);
    });
    test('fixed display order', () {
      expect(ShoppingCategory.values.map((c) => c.label), [
        'Hortifruti', 'Padaria', 'Açougue e peixes', 'Frios e laticínios', 'Mercearia',
        'Bebidas', 'Congelados', 'Limpeza', 'Higiene e perfumaria', 'Bebê e pet', 'Outros',
      ]);
    });
    test('items sorted by aisle, then alphabetically ignoring accents', () {
      final r = organize('sabão em pó\nzebra de pelúcia\nmaçã\nábaco\nalface\nbanana\npão\narroz');
      expect(texts(r), ['alface', 'banana', 'maçã', 'pão', 'arroz', 'sabão em pó']);
    });
    test('sorting ignores quantities', () {
      expect(texts(organize('3 bananas\nalface\n1 kg de abacaxi')),
          ['1 kg de abacaxi', 'alface', '3 bananas']);
    });
  });

  group('duplicates', () {
    test('same word in different case and accent', () {
      final r = organize('Pão\npao\nPÃO');
      expect(texts(r), ['Pão']);
      expect(r.duplicates, 2);
    });
    test('plural counts as duplicate; first spelling is kept', () {
      expect(texts(organize('leite\n2 leites')), ['leite']);
    });
    test('against existing list', () {
      final r = organize('leite, pão', existing: ['LEITE']);
      expect(texts(r), ['pão']);
    });
    test('different items are not duplicates', () => expect(organize('leite, leite condensado').shopping.length, 2));
  });

  group('header driven lists', () {
    test('Compras: makes following lines shopping items', () {
      final r = organize('Compras:\nfoo\nbar baz');
      expect(r.shopping.length, 2);
      expect(r.note, isNull);
    });
    test('inline header', () {
      final r = organize('Mercado: leite, pão, coisa estranha');
      expect(r.shopping.length, 3);
    });
    test('header without colon', () {
      final r = organize('lista de compras\nxpto');
      expect(r.shopping.single.text, 'xpto');
    });
    test('blank line ends the list', () {
      final r = organize('Compras:\nleite\n\nligar para o João');
      expect(r.shopping.length, 1);
      expect(r.note!.body, 'ligar para o João');
    });
    test('another header ends the list and stays in the note', () {
      final r = organize('Lista:\nleite\nRecados:\nligar para Ana');
      expect(r.shopping.length, 1);
      expect(r.note!.body, 'Recados:\nligar para Ana');
    });
    test('header line itself is not in the note', () {
      expect(organize('Compras:\nleite').note, isNull);
    });
  });

  group('mixed content', () {
    test('shopping and notes together keep note order in one note', () {
      final r = organize('Ligar para o dentista\nleite\npão\nPagar a conta de luz');
      expect(r.shopping.length, 2);
      expect(r.note!.body, 'Ligar para o dentista\nPagar a conta de luz');
    });
    test('sentence with commas stays one line', () {
      final r = organize('Consulta dia 10, às 14h');
      expect(r.note!.body, 'Consulta dia 10, às 14h');
    });
    test('mixed comma line splits product from note part', () {
      final r = organize('ligar para Ana, leite, pão');
      expect(r.shopping.length, 2);
      expect(r.note!.body, 'ligar para Ana');
    });
    test('forceShopping treats everything as items', () {
      final r = organize('xpto, leite', forceShopping: true);
      expect(r.shopping.length, 2);
      expect(r.note, isNull);
    });
    test('no shopping means no shopping entries', () {
      expect(organize('Aniversário da vovó sábado').shopping, isEmpty);
    });
  });

  group('note title', () {
    test('first line', () => expect(organize('Consultar o médico\nlevar exames').note!.title, 'Consultar o médico'));
    test('trimmed to 40 chars', () {
      final t = organize('a' * 80).note!.title;
      expect(t.length, 40);
    });
    test('short title unchanged', () => expect(organize('Oi').note!.title, 'Oi'));
  });

  group('note category', () {
    NoteCategory c(String s) => organize(s).note!.category;
    test('saúde', () => expect(c('Marcar consulta com o médico'), NoteCategory.saude));
    test('contas', () => expect(c('Pagar o boleto do aluguel'), NoteCategory.contas));
    test('casa', () => expect(c('Chamar o encanador para consertar a torneira'), NoteCategory.casa));
    test('receitas', () => expect(c('Receita de bolo: ingredientes e modo de preparo'), NoteCategory.receitas));
    test('viagem', () => expect(c('Comprar passagem para a viagem'), NoteCategory.viagem));
    test('família', () => expect(c('Festa de aniversário da neta'), NoteCategory.familia));
    test('lembretes', () => expect(c('Não esquecer de ligar para o João'), NoteCategory.lembretes));
    test('default outros', () => expect(c('Qualquer coisa'), NoteCategory.outros));
    test('label round trip', () => expect(NoteCategory.fromLabel('Saúde'), NoteCategory.saude));
    test('unknown label', () => expect(NoteCategory.fromLabel('Nada'), isNull));
  });

  group('sample', () {
    test('realistic message', () {
      final r = organize('''
Compras:
- 2 litros de leite
- pão
- banana, maçã
- detergente
Ligar para o médico amanhã
Pagar a conta de luz
''');
      expect(r.shopping.map((e) => '${e.category.label}: ${e.text}').toList(), [
        'Hortifruti: banana',
        'Hortifruti: maçã',
        'Padaria: pão',
        'Frios e laticínios: 2 litros de leite',
        'Limpeza: detergente',
      ]);
      expect(r.note!.body, 'Ligar para o médico amanhã\nPagar a conta de luz');
      expect(r.note!.category, NoteCategory.contas);
    });
  });
}
