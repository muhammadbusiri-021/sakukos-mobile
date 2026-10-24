import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakukos/core/formatters.dart';

void main() {
  group('SakuKosFormatters', () {
    test('rupiah formatting displays clean nominal without +/- signs', () {
      expect(SakuKosFormatters.rupiah(50000), 'Rp 50.000');
      expect(SakuKosFormatters.rupiah(0), 'Rp 0');
      expect(SakuKosFormatters.rupiah(-15000), 'Rp 15.000');
      expect(SakuKosFormatters.rupiah(1250000), 'Rp 1.250.000');
    });

    test('indonesianDate formats day and month in Indonesian', () {
      final date = DateTime(2026, 10, 22); // Thursday
      final formatted = SakuKosFormatters.indonesianDate(date);
      expect(formatted, 'Kamis, 22 Oktober 2026');
    });

    test('time formats hour and minute with 2 digits', () {
      final date = DateTime(2026, 10, 22, 9, 5);
      final formatted = SakuKosFormatters.time(date);
      expect(formatted, '09:05');
    });

    test('toTitleCase formats words to Title Case and handles edge cases', () {
      expect(SakuKosFormatters.toTitleCase('makan'), 'Makan');
      expect(SakuKosFormatters.toTitleCase('MAKAN'), 'Makan');
      expect(SakuKosFormatters.toTitleCase('paket data'), 'Paket Data');
      expect(SakuKosFormatters.toTitleCase('  gaji  '), 'Gaji');
      expect(SakuKosFormatters.toTitleCase(''), '');
    });
  });

  group('ThousandsSeparatorInputFormatter Tests', () {
    const formatter = ThousandsSeparatorInputFormatter();

    test('formats numeric strings with thousand dots correctly', () {
      final val1 = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1000',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(val1.text, '1.000');
      expect(val1.selection.end, 5);

      final val2 = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '150000',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(val2.text, '150.000');
      expect(val2.selection.end, 7);

      final val3 = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1500000',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      expect(val3.text, '1.500.000');
      expect(val3.selection.end, 9);
    });

    test('handles empty and non-digit inputs gracefully', () {
      final emptyVal = formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue.empty,
      );
      expect(emptyVal.text, '');

      final nonDigitVal = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'abc',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(nonDigitVal.text, '');
    });
  });
}
