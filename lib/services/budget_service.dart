import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service singleton untuk mengelola batas anggaran (budget) anak kos secara lokal via Hive.
class BudgetService {
  BudgetService._internal();

  static final BudgetService _instance = BudgetService._internal();

  /// Mengakses instance singleton [BudgetService].
  factory BudgetService() => _instance;

  static const String boxName = 'settings_box';
  static const String keyDailyBudget = 'daily_budget';
  static const double defaultDailyBudget = 50000.0;

  Box? _box;

  /// Getter untuk box Hive pengaturan aktif.
  Box get box {
    final activeBox = _box;
    if (activeBox == null || !activeBox.isOpen) {
      throw StateError(
        'BudgetService belum diinisialisasi. Panggil BudgetService().init() terlebih dahulu.',
      );
    }
    return activeBox;
  }

  /// Membuka box pengaturan jika belum terbuka.
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(boxName);
    }
  }

  /// Mengambil batas jatah pengeluaran per hari yang tersimpan (default: 50.000).
  double getDailyBudget() {
    final value = box.get(keyDailyBudget, defaultValue: defaultDailyBudget);
    if (value is num) return value.toDouble();
    return defaultDailyBudget;
  }

  /// Menyimpan batas jatah harian baru secara langsung.
  Future<void> setDailyBudget(double amount) async {
    await box.put(keyDailyBudget, amount);
  }

  /// Menghitung otomatis jatah per hari dari total uang saku bulanan
  /// berdasarkan jumlah hari kalender di bulan berjalan (28, 29, 30, atau 31 hari).
  Future<void> setMonthlyBudget(double monthlyAmount) async {
    final now = DateTime.now();
    // Menghitung jumlah hari pada bulan saat ini
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final days = max(1, totalDaysInMonth);
    final calculatedDaily = monthlyAmount / days;
    await setDailyBudget(calculatedDaily);
  }

  /// ValueListenable agar UI otomatis reaktif ketika batas budget diperbarui.
  ValueListenable<Box> get listenable => box.listenable();
}
