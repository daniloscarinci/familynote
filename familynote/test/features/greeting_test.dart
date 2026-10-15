import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/features/home/greeting.dart';

void main() {
  DateTime at(int h) => DateTime(2026, 10, 15, h);

  test('time of day', () {
    expect(greeting(at(7), 'Maria'), 'Bom dia, Maria');
    expect(greeting(at(14), 'Maria'), 'Boa tarde, Maria');
    expect(greeting(at(21), 'Maria'), 'Boa noite, Maria');
    expect(greeting(at(3), 'Maria'), 'Boa noite, Maria');
  });

  test('first name only', () {
    expect(greeting(at(9), 'Maria da Silva'), 'Bom dia, Maria');
    expect(greeting(at(9), '  Vovó Rosa '), 'Bom dia, Vovó');
  });

  test('no name -> Olá', () {
    expect(greeting(at(9), null), 'Olá');
    expect(greeting(at(9), '   '), 'Olá');
  });
}
