import 'package:flutter_test/flutter_test.dart';
import 'package:sakukos/models/debt_item.dart';
import 'package:sakukos/models/transaction_item.dart';
import 'package:sakukos/services/csv_export_service.dart';

void main() {
  late CsvExportService service;

  setUp(() {
    service = CsvExportService();
  });

  group('CsvExportService - generateTransactionsCsv', () {
    test('generates valid header with UTF-8 BOM when list is empty', () {
      final csv = service.generateTransactionsCsv([]);
      expect(csv.startsWith(CsvExportService.utf8Bom), isTrue);

      final lines = csv.substring(1).trim().split('\n');
      expect(lines.length, 1);
      expect(
        lines[0].trim(),
        'Tanggal,Jam,Tipe,Kategori,Judul,Nominal,Catatan',
      );
    });

    test('formats transaction rows accurately including income and expense', () {
      final items = [
        TransactionItem(
          id: 'tx_1',
          title: 'Makan Nasi Padang',
          amount: 25000,
          category: TransactionCategory.makan,
          isExpense: true,
          date: DateTime(2026, 10, 23, 12, 30),
          note: 'Porsi rendang komplit',
        ),
        TransactionItem(
          id: 'tx_2',
          title: 'Gaji Asisten Lab',
          amount: 350000,
          category: TransactionCategory.belajar,
          isExpense: false,
          date: DateTime(2026, 10, 22, 9, 15),
          note: null,
        ),
      ];

      final csv = service.generateTransactionsCsv(items);
      expect(csv.startsWith(CsvExportService.utf8Bom), isTrue);

      final lines = csv.substring(1).trim().split('\n');
      expect(lines.length, 3);
      expect(
        lines[0].trim(),
        'Tanggal,Jam,Tipe,Kategori,Judul,Nominal,Catatan',
      );
      expect(
        lines[1].trim(),
        '2026-10-23,12:30,Pengeluaran,"Makan","Makan Nasi Padang",25000,"Porsi rendang komplit"',
      );
      expect(
        lines[2].trim(),
        '2026-10-22,09:15,Pemasukan,"Belajar","Gaji Asisten Lab",350000,""',
      );
    });

    test('escapes special characters such as double quotes and commas in title and note', () {
      final items = [
        TransactionItem(
          id: 'tx_special',
          title: 'Beli "Buku, Pulpen", & Penggaris',
          amount: 45000,
          category: TransactionCategory.belajar,
          isExpense: true,
          date: DateTime(2026, 10, 20, 16, 45),
          note: 'Catatan: diskon 10%, "tokopedia"',
        ),
      ];

      final csv = service.generateTransactionsCsv(items);
      final lines = csv.substring(1).trim().split('\n');
      expect(
        lines[1].trim(),
        '2026-10-20,16:45,Pengeluaran,"Belajar","Beli ""Buku, Pulpen"", & Penggaris",45000,"Catatan: diskon 10%, ""tokopedia"""',
      );
    });
  });

  group('CsvExportService - generateDebtsCsv', () {
    test('generates valid header with UTF-8 BOM when list is empty', () {
      final csv = service.generateDebtsCsv([]);
      expect(csv.startsWith(CsvExportService.utf8Bom), isTrue);

      final lines = csv.substring(1).trim().split('\n');
      expect(lines.length, 1);
      expect(
        lines[0].trim(),
        'Tanggal,Nama Teman,Keperluan,Nominal,Status',
      );
    });

    test('formats debt rows with Lunas and Belum Lunas status', () {
      final items = [
        DebtItem(
          id: 'debt_1',
          friendName: 'Budi Santoso',
          description: 'Talangan Mie Ayam',
          amount: 15000,
          date: DateTime(2026, 10, 21, 19, 0),
          isSettled: false,
        ),
        DebtItem(
          id: 'debt_2',
          friendName: 'Andi, Pratama',
          description: 'Patungan "Kopi Susu"',
          amount: 22000,
          date: DateTime(2026, 10, 20, 20, 30),
          isSettled: true,
        ),
      ];

      final csv = service.generateDebtsCsv(items);
      expect(csv.startsWith(CsvExportService.utf8Bom), isTrue);

      final lines = csv.substring(1).trim().split('\n');
      expect(lines.length, 3);
      expect(
        lines[0].trim(),
        'Tanggal,Nama Teman,Keperluan,Nominal,Status',
      );
      expect(
        lines[1].trim(),
        '2026-10-21,"Budi Santoso","Talangan Mie Ayam",15000,Belum Lunas',
      );
      expect(
        lines[2].trim(),
        '2026-10-20,"Andi, Pratama","Patungan ""Kopi Susu""",22000,Lunas',
      );
    });
  });
}
