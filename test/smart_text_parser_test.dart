import 'package:flutter_test/flutter_test.dart';
import 'package:sakukos/models/transaction_item.dart';
import 'package:sakukos/services/smart_text_parser.dart';

void main() {
  group('SmartTextParser Core Specifications', () {
    test('parses "makan bakso 15k" correctly', () {
      final result = SmartTextParser.parse('makan bakso 15k');
      expect(result, isNotNull);
      expect(result!.title, 'Makan Bakso');
      expect(result.amount, 15000.0);
      expect(result.category, TransactionCategory.makan);
      expect(result.isExpense, isTrue);
    });

    test('parses "bensin 20rb" correctly', () {
      final result = SmartTextParser.parse('bensin 20rb');
      expect(result, isNotNull);
      expect(result!.title, 'Bensin');
      expect(result.amount, 20000.0);
      expect(result.category, TransactionCategory.transport);
      expect(result.isExpense, isTrue);
    });

    test('parses "gaji aslab 250k" correctly with fallback to Makan', () {
      final result = SmartTextParser.parse('gaji aslab 250k');
      expect(result, isNotNull);
      expect(result!.title, 'Gaji Aslab');
      expect(result.amount, 250000.0);
      expect(result.category, TransactionCategory.makan);
      expect(result.isExpense, isFalse);
    });

    test('parses "laundry kiloan 12.000" correctly', () {
      final result = SmartTextParser.parse('laundry kiloan 12.000');
      expect(result, isNotNull);
      expect(result!.title, 'Laundry Kiloan');
      expect(result.amount, 12000.0);
      expect(result.category, TransactionCategory.kosan);
      expect(result.isExpense, isTrue);
    });

    test('parses "kiriman bulanan 1.5jt" correctly with fallback to Makan', () {
      final result = SmartTextParser.parse('kiriman bulanan 1.5jt');
      expect(result, isNotNull);
      expect(result!.title, 'Kiriman Bulanan');
      expect(result.amount, 1500000.0);
      expect(result.category, TransactionCategory.makan);
      expect(result.isExpense, isFalse);
    });

    test('parses long sentence retaining location and saving original note', () {
      final result = SmartTextParser.parse(
        'makan mie ayam di warung cak soni bayar 18k',
      );
      expect(result, isNotNull);
      expect(result!.title, 'Makan Mie Ayam Di Warung Cak Soni');
      expect(result.amount, 18000.0);
      expect(result.category, TransactionCategory.makan);
      expect(result.isExpense, isTrue);
      expect(result.note, 'makan mie ayam di warung cak soni bayar 18k');
    });
  });

  group('SmartTextParser Amount Format Variations', () {
    test('handles suffix k and K (uppercase/lowercase)', () {
      final r1 = SmartTextParser.parse('nasi uduk 18k');
      final r2 = SmartTextParser.parse('nasi uduk 18K');
      expect(r1?.amount, 18000.0);
      expect(r2?.amount, 18000.0);
    });

    test('handles suffix rb and ribu with and without space', () {
      final r1 = SmartTextParser.parse('kopi susu 18rb');
      final r2 = SmartTextParser.parse('kopi susu 18 rb');
      final r3 = SmartTextParser.parse('kopi susu 18ribu');
      final r4 = SmartTextParser.parse('kopi susu 18 ribu');
      expect(r1?.amount, 18000.0);
      expect(r2?.amount, 18000.0);
      expect(r3?.amount, 18000.0);
      expect(r4?.amount, 18000.0);
    });

    test('handles thousand dots and plain numbers', () {
      final r1 = SmartTextParser.parse('token listrik 50.000');
      final r2 = SmartTextParser.parse('token listrik 50000');
      expect(r1?.amount, 50000.0);
      expect(r2?.amount, 50000.0);
    });

    test('handles million formats with dot and comma (1.5jt / 1,5juta)', () {
      final r1 = SmartTextParser.parse('bayar kos 1.5jt');
      final r2 = SmartTextParser.parse('bayar kos 1,5 juta');
      final r3 = SmartTextParser.parse('bayar kos 2jt');
      expect(r1?.amount, 1500000.0);
      expect(r2?.amount, 1500000.0);
      expect(r3?.amount, 2000000.0);
    });

    test('handles Rp prefix with various spacings and dots', () {
      final r1 = SmartTextParser.parse('makan siang rp 25.000');
      final r2 = SmartTextParser.parse('makan siang Rp. 25k');
      final r3 = SmartTextParser.parse('makan siang rp25000');
      expect(r1?.amount, 25000.0);
      expect(r1?.title, 'Makan Siang');
      expect(r2?.amount, 25000.0);
      expect(r2?.title, 'Makan Siang');
      expect(r3?.amount, 25000.0);
      expect(r3?.title, 'Makan Siang');
    });
  });

  group('SmartTextParser Category Recognition', () {
    test('recognizes Makan keywords', () {
      expect(SmartTextParser.parse('ayam geprek 18k')?.category,
          TransactionCategory.makan);
      expect(SmartTextParser.parse('mie ayam 15k')?.category,
          TransactionCategory.makan);
      expect(SmartTextParser.parse('martabak manis 25k')?.category,
          TransactionCategory.makan);
    });

    test('recognizes Kosan keywords', () {
      expect(SmartTextParser.parse('beli galon 19k')?.category,
          TransactionCategory.kosan);
      expect(SmartTextParser.parse('tagihan wifi 150k')?.category,
          TransactionCategory.kosan);
      expect(SmartTextParser.parse('sabun dan deterjen 30k')?.category,
          TransactionCategory.kosan);
    });

    test('recognizes Nongkrong keywords', () {
      expect(SmartTextParser.parse('nongki santai 35k')?.category,
          TransactionCategory.nongkrong);
      expect(SmartTextParser.parse('ngopi di kafe 28k')?.category,
          TransactionCategory.nongkrong);
      expect(SmartTextParser.parse('warkop pancong 15k')?.category,
          TransactionCategory.nongkrong);
    });

    test('recognizes Transport keywords', () {
      expect(SmartTextParser.parse('isi pertalite 25k')?.category,
          TransactionCategory.transport);
      expect(SmartTextParser.parse('ojol ke stasiun 14k')?.category,
          TransactionCategory.transport);
      expect(SmartTextParser.parse('parkir motor 2000')?.category,
          TransactionCategory.transport);
    });

    test('recognizes Belajar keywords', () {
      expect(SmartTextParser.parse('print skripsi 25k')?.category,
          TransactionCategory.belajar);
      expect(SmartTextParser.parse('fotokopi materi 5000')?.category,
          TransactionCategory.belajar);
      expect(SmartTextParser.parse('beli buku tulis 12k')?.category,
          TransactionCategory.belajar);
    });
  });

  group('SmartTextParser Income Detection', () {
    test('flags income keywords as isExpense: false', () {
      expect(SmartTextParser.parse('uang saku bulanan 1jt')?.isExpense, isFalse);
      expect(SmartTextParser.parse('transferan orang tua 500k')?.isExpense, isFalse);
      expect(SmartTextParser.parse('cashback shopeepay 10rb')?.isExpense, isFalse);
      expect(SmartTextParser.parse('bonus asisten lab 300k')?.isExpense, isFalse);
      expect(SmartTextParser.parse('dapat uang saku 200k')?.isExpense, isFalse);
    });

    test('defaults to isExpense: true when no income keyword present', () {
      expect(SmartTextParser.parse('nasi goreng 15k')?.isExpense, isTrue);
      expect(SmartTextParser.parse('bensin beat 20k')?.isExpense, isTrue);
    });
  });

  group('SmartTextParser Edge Cases and Fallbacks', () {
    test('returns null for empty or whitespace strings', () {
      expect(SmartTextParser.parse(''), isNull);
      expect(SmartTextParser.parse('    '), isNull);
    });

    test('returns null when no numeric amount is present', () {
      expect(SmartTextParser.parse('selamat pagi dunia'), isNull);
      expect(SmartTextParser.parse('makan siang nasi padang enak'), isNull);
    });

    test('uses fallback category as title if title is empty after amount extraction', () {
      final result = SmartTextParser.parse('18k');
      expect(result, isNotNull);
      expect(result!.amount, 18000.0);
      expect(result.title, TransactionCategory.makan);
      expect(result.category, TransactionCategory.makan);
    });

    test('uses food category as title if input is only food and amount', () {
      final result = SmartTextParser.parse('makan 20k');
      expect(result, isNotNull);
      expect(result!.title, 'Makan');
      expect(result.category, TransactionCategory.makan);
    });
  });
}
