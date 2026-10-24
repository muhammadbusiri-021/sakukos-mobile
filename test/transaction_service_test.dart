import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sakukos/models/transaction_item.dart';
import 'package:sakukos/services/transaction_service.dart';

void main() {
  group('TransactionItem Model', () {
    test('toMap and fromMap should serialize and deserialize correctly', () {
      final now = DateTime.now();
      final item = TransactionItem(
        id: 'tx_123',
        title: 'Nasi Padang',
        amount: 25000.0,
        category: TransactionCategory.makan,
        isExpense: true,
        date: now,
        note: 'Pakai rendang & es teh',
      );

      final map = item.toMap();
      final fromMap = TransactionItem.fromMap(map);

      expect(fromMap.id, item.id);
      expect(fromMap.title, item.title);
      expect(fromMap.amount, item.amount);
      expect(fromMap.category, item.category);
      expect(fromMap.isExpense, item.isExpense);
      expect(fromMap.date.toIso8601String(), item.date.toIso8601String());
      expect(fromMap.note, item.note);
    });

    test('fromMap handles null note and int amount safely', () {
      final map = {
        'id': 'tx_456',
        'title': 'Kiriman Orang Tua',
        'amount': 1500000, // integer from JSON/Hive
        'category': TransactionCategory.lainnya,
        'isExpense': false,
        'date': DateTime.now().toIso8601String(),
        'note': null,
      };

      final item = TransactionItem.fromMap(map);
      expect(item.amount, 1500000.0);
      expect(item.note, isNull);
      expect(item.isExpense, isFalse);
    });
  });

  group('TransactionService Database Tests', () {
    late Directory tempDir;
    late TransactionService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sakukos_test_');
      Hive.init(tempDir.path);
      service = TransactionService();
      await service.init();
      await service.box.clear();
    });

    tearDown(() async {
      await service.box.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('addTransaction and getAllTransactions (sorted newest first)', () async {
      final olderDate = DateTime(2026, 10, 10, 10, 0);
      final newerDate = DateTime(2026, 10, 20, 15, 30);

      final item1 = TransactionItem(
        id: '1',
        title: 'Beli Buku',
        amount: 50000,
        category: TransactionCategory.belajar,
        isExpense: true,
        date: olderDate,
      );

      final item2 = TransactionItem(
        id: '2',
        title: 'Kopi Kenangan',
        amount: 22000,
        category: TransactionCategory.nongkrong,
        isExpense: true,
        date: newerDate,
      );

      await service.addTransaction(item1);
      await service.addTransaction(item2);

      final list = service.getAllTransactions();
      expect(list.length, 2);
      // Newest first: item2 should be index 0
      expect(list[0].id, '2');
      expect(list[1].id, '1');
    });

    test('getTodayTotalExpense and getMonthTotalExpense calculate accurately', () async {
      final now = DateTime.now();
      final todayExpense = TransactionItem(
        id: 'today_exp',
        title: 'Makan Siang',
        amount: 20000,
        category: TransactionCategory.makan,
        isExpense: true,
        date: now,
      );

      final todayIncome = TransactionItem(
        id: 'today_inc',
        title: 'Cashback',
        amount: 5000,
        category: TransactionCategory.lainnya,
        isExpense: false,
        date: now,
      );

      // Yesterday or another day in the same month
      final anotherDayInMonth = now.day > 1
          ? now.subtract(const Duration(days: 1))
          : now.add(const Duration(days: 1));

      final anotherDayExpense = TransactionItem(
        id: 'other_day_exp',
        title: 'Token Listrik Kos',
        amount: 100000,
        category: TransactionCategory.kosan,
        isExpense: true,
        date: anotherDayInMonth,
      );

      await service.addTransaction(todayExpense);
      await service.addTransaction(todayIncome);
      await service.addTransaction(anotherDayExpense);

      expect(service.getTodayTotalExpense(), 20000.0);
      expect(service.getMonthTotalExpense(), 120000.0);
    });

    test('getMonthTotalIncome and getTotalBalance calculate accurately', () async {
      final now = DateTime.now();

      // Pemasukan bulan ini: 500.000
      await service.addTransaction(TransactionItem(
        id: 'inc_1',
        title: 'Kiriman Bulanan',
        amount: 500000,
        category: TransactionCategory.lainnya,
        isExpense: false,
        date: now,
      ));

      // Pemasukan bulan ini: 50.000
      await service.addTransaction(TransactionItem(
        id: 'inc_2',
        title: 'Cashback Belanja',
        amount: 50000,
        category: TransactionCategory.lainnya,
        isExpense: false,
        date: now,
      ));

      // Pengeluaran bulan ini: 120.000
      await service.addTransaction(TransactionItem(
        id: 'exp_1',
        title: 'Makan Bareng',
        amount: 120000,
        category: TransactionCategory.makan,
        isExpense: true,
        date: now,
      ));

      // Pemasukan bulan lalu (bukan bulan ini)
      final lastMonth = DateTime(now.year, now.month - 1, 15);
      await service.addTransaction(TransactionItem(
        id: 'inc_old',
        title: 'Gaji Bulan Lalu',
        amount: 200000,
        category: TransactionCategory.lainnya,
        isExpense: false,
        date: lastMonth,
      ));

      // Total pemasukan bulan ini: 500.000 + 50.000 = 550.000
      expect(service.getMonthTotalIncome(), 550000.0);

      // Total saldo kas sepanjang masa:
      // (500.000 + 50.000 + 200.000) - (120.000) = 750.000 - 120.000 = 630.000
      expect(service.getTotalBalance(), 630000.0);
    });

    test('deleteTransaction removes transaction from box', () async {
      final item = TransactionItem(
        id: 'tx_del',
        title: 'Salah Catat',
        amount: 10000,
        category: TransactionCategory.lainnya,
        isExpense: true,
        date: DateTime.now(),
      );

      await service.addTransaction(item);
      expect(service.getAllTransactions().length, 1);

      await service.deleteTransaction('tx_del');
      expect(service.getAllTransactions().isEmpty, isTrue);
    });

    test('updateTransaction modifies existing transaction in box', () async {
      final item = TransactionItem(
        id: 'tx_update',
        title: 'Makan Bakso',
        amount: 15000,
        category: TransactionCategory.makan,
        isExpense: true,
        date: DateTime.now(),
        note: 'Bakso urat',
      );

      await service.addTransaction(item);
      expect(service.getAllTransactions().first.title, 'Makan Bakso');
      expect(service.getAllTransactions().first.amount, 15000.0);

      final updated = TransactionItem(
        id: 'tx_update',
        title: 'Makan Bakso Spesial',
        amount: 22000,
        category: TransactionCategory.makan,
        isExpense: true,
        date: item.date,
        note: 'Tambah pangsit dan es teh',
      );

      await service.updateTransaction(updated);
      final list = service.getAllTransactions();
      expect(list.length, 1);
      expect(list.first.title, 'Makan Bakso Spesial');
      expect(list.first.amount, 22000.0);
      expect(list.first.note, 'Tambah pangsit dan es teh');
    });

    test('getLast7DaysExpenses returns exactly 7 days and sums only expenses',
        () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      final eightDaysAgo = today.subtract(const Duration(days: 8));

      // Transaksi hari ini: pengeluaran 15.000 & pemasukan 50.000
      await service.addTransaction(TransactionItem(
        id: 'tx_today_exp',
        title: 'Makan Hari Ini',
        amount: 15000,
        category: TransactionCategory.makan,
        isExpense: true,
        date: now,
      ));
      await service.addTransaction(TransactionItem(
        id: 'tx_today_inc',
        title: 'Pemasukan Hari Ini',
        amount: 50000,
        category: TransactionCategory.lainnya,
        isExpense: false,
        date: now,
      ));

      // Transaksi 2 hari lalu: pengeluaran 25.000
      await service.addTransaction(TransactionItem(
        id: 'tx_2days_exp',
        title: 'Beli Catatan',
        amount: 25000,
        category: TransactionCategory.belajar,
        isExpense: true,
        date: twoDaysAgo.add(const Duration(hours: 14)),
      ));

      // Transaksi 8 hari lalu: di luar jangkauan 7 hari terakhir
      await service.addTransaction(TransactionItem(
        id: 'tx_old_exp',
        title: 'Pengeluaran Lama',
        amount: 100000,
        category: TransactionCategory.kosan,
        isExpense: true,
        date: eightDaysAgo,
      ));

      final result = service.getLast7DaysExpenses();

      // Harus berisi tepat 7 entri hari
      expect(result.length, 7);

      // Pastikan hari ini memiliki nilai 15.000 (pemasukan diabaikan)
      expect(result[today], 15000.0);

      // Pastikan 2 hari lalu bernilai 25.000
      expect(result[twoDaysAgo], 25000.0);

      // Pastikan hari kemarin (tanpa transaksi) bernilai 0.0
      final yesterday = today.subtract(const Duration(days: 1));
      expect(result[yesterday], 0.0);

      // Pastikan transaksi 8 hari lalu tidak masuk dalam total
      final totalLast7Days =
          result.values.fold<double>(0.0, (sum, val) => sum + val);
      expect(totalLast7Days, 40000.0);
    });
  });
}
