import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_item.dart';

/// Service singleton untuk mengelola penyimpanan data transaksi secara lokal via Hive.
class TransactionService {
  TransactionService._internal();

  static final TransactionService _instance = TransactionService._internal();

  /// Mengakses instance singleton [TransactionService].
  factory TransactionService() => _instance;

  static const String boxName = 'transactions_box';
  Box? _box;

  /// Getter untuk box Hive aktif. Melemparkan [StateError] jika belum diinisialisasi.
  Box get box {
    final activeBox = _box;
    if (activeBox == null || !activeBox.isOpen) {
      throw StateError(
        'TransactionService belum diinisialisasi. Panggil TransactionService().init() terlebih dahulu.',
      );
    }
    return activeBox;
  }

  /// Membuka box transaksi jika belum terbuka.
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(boxName);
    }
  }

  /// Menambahkan atau memperbarui transaksi ke dalam Hive berdasarkan ID.
  Future<void> addTransaction(TransactionItem item) async {
    await box.put(item.id, item.toMap());
  }

  /// Memperbarui transaksi yang sudah ada di database berdasarkan [item.id].
  Future<void> updateTransaction(TransactionItem item) async {
    await box.put(item.id, item.toMap());
  }

  /// Menghapus transaksi dari database berdasarkan [id].
  Future<void> deleteTransaction(String id) async {
    await box.delete(id);
  }

  /// Mengambil seluruh daftar transaksi yang terurut dari tanggal terbaru ke terlama.
  List<TransactionItem> getAllTransactions() {
    final items = <TransactionItem>[];

    for (final value in box.values) {
      if (value is Map) {
        try {
          items.add(TransactionItem.fromMap(value));
        } catch (_) {
          // Abaikan jika ada data korup yang tidak cocok formatnya
        }
      }
    }

    // Urutkan dari tanggal terbaru ke terlama
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  /// Menghitung total pengeluaran khusus hari ini (berdasarkan tanggal, bulan, dan tahun saat ini).
  double getTodayTotalExpense() {
    final now = DateTime.now();
    return getAllTransactions()
        .where(
          (item) =>
              item.isExpense &&
              item.date.year == now.year &&
              item.date.month == now.month &&
              item.date.day == now.day,
        )
        .fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  /// Menghitung total pengeluaran khusus bulan ini (berdasarkan bulan dan tahun saat ini).
  double getMonthTotalExpense() {
    final now = DateTime.now();
    return getAllTransactions()
        .where(
          (item) =>
              item.isExpense &&
              item.date.year == now.year &&
              item.date.month == now.month,
        )
        .fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  /// Menghitung total pemasukan khusus bulan ini (berdasarkan bulan dan tahun saat ini).
  double getMonthTotalIncome() {
    final now = DateTime.now();
    return getAllTransactions()
        .where(
          (item) =>
              !item.isExpense &&
              item.date.year == now.year &&
              item.date.month == now.month,
        )
        .fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  /// Menghitung total seluruh saldo kas (Total Seluruh Pemasukan - Total Seluruh Pengeluaran).
  double getTotalBalance() {
    final all = getAllTransactions();
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (final item in all) {
      if (item.isExpense) {
        totalExpense += item.amount;
      } else {
        totalIncome += item.amount;
      }
    }

    return totalIncome - totalExpense;
  }

  /// Mengambil pengelompokan total pengeluaran untuk 7 hari terakhir (dari 6 hari lalu sampai hari ini).
  /// Key bertipe DateTime yang dinormalisasi (tahun, bulan, hari), value berupa total nominal pengeluaran.
  Map<DateTime, double> getLast7DaysExpenses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <DateTime, double>{};

    // Inisialisasi 7 hari berurutan (6 hari lalu -> hari ini) dengan nilai 0.0
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      result[date] = 0.0;
    }

    final allTransactions = getAllTransactions();
    for (final item in allTransactions) {
      if (!item.isExpense) continue;

      final itemDate =
          DateTime(item.date.year, item.date.month, item.date.day);
      if (result.containsKey(itemDate)) {
        result[itemDate] = (result[itemDate] ?? 0.0) + item.amount;
      }
    }

    return result;
  }

  /// ValueListenable agar UI (misal: ValueListenableBuilder) dapat bereaksi
  /// secara otomatis ketika ada transaksi yang ditambah, diubah, atau dihapus.
  ValueListenable<Box> get listenable => box.listenable();
}
