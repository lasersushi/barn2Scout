import 'package:barn2scout/features/scouting/widgets/field_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseNumberInput', () {
    test('empty or incomplete input is null', () {
      expect(parseNumberInput(''), isNull);
      expect(parseNumberInput('.'), isNull);
    });

    test('whole numbers stay int', () {
      expect(parseNumberInput('118'), isA<int>().having((n) => n, 'value', 118));
      expect(parseNumberInput('118.0'), isA<int>());
    });

    test('decimals stay double', () {
      expect(parseNumberInput('27.5'), 27.5);
      expect(parseNumberInput('.5'), 0.5);
    });

    test('trailing dot keeps the number', () {
      expect(parseNumberInput('5.'), 5);
    });
  });
}
