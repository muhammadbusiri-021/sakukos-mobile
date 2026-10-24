import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt_item.dart';

/// Service singleton untuk mengelola catatan talangan dan uang patungan anak kos.
class DebtService {
  DebtService._internal();

  static final DebtService _instance = DebtService._internal();

  /// Mengakses instance singleton [DebtService].
  factory DebtService() => _instance;

  static const String boxName = 'debts_box';
  Box? _box;

  /// Getter untuk box Hive aktif. Melemparkan [StateError] jika belum diinisialisasi.
  Box get box {
    final activeBox = _box;
    if (activeBox == null || !activeBox.isOpen) {
      throw StateError(
        'DebtService belum diinisialisasi. Panggil DebtService().init() terlebih dahulu.',
      );
    }
    return activeBox;
  }

  /// Membuka box talangan jika belum terbuka.
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(boxName);
    }
  }

  /// Menambahkan atau memperbarui catatan talangan ke Hive.
  Future<void> addDebt(DebtItem item) async {
    await box.put(item.id, item.toMap());
  }

  /// Mengubah status penyelesaian (lunas / belum lunas) berdasarkan [id].
  Future<void> toggleSettleStatus(String id) async {
    final raw = box.get(id);
    if (raw is Map) {
      try {
        final current = DebtItem.fromMap(raw);
        final updated = current.copyWith(isSettled: !current.isSettled);
        await box.put(id, updated.toMap());
      } catch (_) {
        // Abaikan data tidak valid
      }
    }
  }

  /// Menghapus catatan talangan berdasarkan [id].
  Future<void> deleteDebt(String id) async {
    await box.delete(id);
  }

  /// Mengambil semua catatan talangan mentah dari box terurut dari terbaru.
  List<DebtItem> getAllDebts() {
    final items = <DebtItem>[];
    for (final value in box.values) {
      if (value is Map) {
        try {
          items.add(DebtItem.fromMap(value));
        } catch (_) {
          // Abaikan jika ada data korup
        }
      }
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  /// Mengambil daftar talangan yang BELUM lunas (`isSettled == false`), terurut dari terbaru.
  List<DebtItem> getActiveDebts() {
    return getAllDebts().where((item) => !item.isSettled).toList();
  }

  /// Mengambil daftar talangan yang SUDAH lunas (`isSettled == true`), terurut dari terbaru.
  List<DebtItem> getSettledDebts() {
    return getAllDebts().where((item) => item.isSettled).toList();
  }

  /// Menghitung total nominal talangan yang belum dikembalikan teman.
  double getTotalUnsettledAmount() {
    return getActiveDebts().fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  /// Notifier agar antarmuka otomatis bereaksi saat ada data talangan yang diubah.
  ValueListenable<Box> get listenable => box.listenable();
}
