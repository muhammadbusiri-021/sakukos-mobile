import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/formatters.dart';
import '../models/transaction_item.dart';

/// Service singleton untuk mengelola daftar kategori transaksi (bawaan & kustom dinamis).
class CategoryService {
  CategoryService._internal();

  static final CategoryService _instance = CategoryService._internal();

  /// Mengakses instance singleton [CategoryService].
  factory CategoryService() => _instance;

  static const String boxName = 'categories_box';
  static const String categoriesKey = 'category_list';

  Box? _box;

  /// Default list kategori awal untuk anak kos.
  static const List<String> defaultCategories = [
    TransactionCategory.makan,
    TransactionCategory.kosan,
    TransactionCategory.nongkrong,
    TransactionCategory.transport,
    TransactionCategory.belajar,
  ];

  /// Kata kunci terlarang yang tidak boleh digunakan sebagai nama kategori kustom.
  static const Set<String> reservedKeywords = {
    'semua',
    'all',
    'lainnya',
  };

  /// Getter untuk box Hive aktif. Melemparkan [StateError] jika belum diinisialisasi.
  Box get box {
    final activeBox = _box;
    if (activeBox == null || !activeBox.isOpen) {
      throw StateError(
        'CategoryService belum diinisialisasi. Panggil CategoryService().init() terlebih dahulu.',
      );
    }
    return activeBox;
  }

  /// Membersihkan daftar mentah dari kata terlarang dan duplikat.
  /// Jika setelah dibersihkan kosong, otomatis memulihkan 5 kategori standar.
  List<String> _cleanAndValidateList(List rawList) {
    final list = rawList
        .map((e) => e.toString().trim())
        .where((c) =>
            c.isNotEmpty &&
            !reservedKeywords.contains(c.toLowerCase()))
        .toList();

    final unique = <String>[];
    for (final item in list) {
      final formatted = SakuKosFormatters.toTitleCase(item);
      if (!unique.any((u) => u.toLowerCase() == formatted.toLowerCase())) {
        unique.add(formatted);
      }
    }

    if (unique.isEmpty) {
      return List<String>.from(defaultCategories);
    }
    return unique;
  }

  /// Membuka box kategori jika belum terbuka dan menginisialisasi kategori default jika kosong.
  /// Juga melakukan pemulihan otomatis: menghapus 'semua'/'all'/'lainnya' dan memulihkan 5 default jika kosong.
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(boxName);
    }

    if (!box.containsKey(categoriesKey)) {
      await box.put(categoriesKey, List<String>.from(defaultCategories));
    } else {
      final raw = box.get(categoriesKey);
      if (raw is List) {
        final cleaned = _cleanAndValidateList(raw);
        final rawStrings = raw.map((e) => e.toString().trim()).toList();
        if (rawStrings.length != cleaned.length ||
            !listEquals(rawStrings, cleaned)) {
          await box.put(categoriesKey, cleaned);
        }
      } else {
        await box.put(categoriesKey, List<String>.from(defaultCategories));
      }
    }
  }

  /// Memeriksa apakah sebuah kategori merupakan salah satu dari 5 kategori default sistem.
  bool isDefaultCategory(String name) {
    final trimmed = name.trim().toLowerCase();
    return defaultCategories.any((cat) => cat.toLowerCase() == trimmed);
  }

  /// Mengambil seluruh daftar kategori yang tersimpan.
  List<String> getCategories() {
    final raw = box.get(categoriesKey);
    if (raw is List) {
      return _cleanAndValidateList(raw);
    }
    return List<String>.from(defaultCategories);
  }

  /// Menambahkan kategori baru ke dalam daftar jika valid dan belum ada.
  /// Mengembalikan pesan error [String] jika gagal, atau [null] jika berhasil.
  Future<String?> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Nama kategori tidak boleh kosong';
    }

    if (reservedKeywords.contains(trimmed.toLowerCase())) {
      return "Nama 'Semua' adalah filter sistem dan tidak dapat digunakan.";
    }

    final current = getCategories();
    final alreadyExists = current.any(
      (c) => c.toLowerCase() == trimmed.toLowerCase(),
    );

    if (alreadyExists) {
      return 'Kategori sudah ada dalam daftar';
    }

    final formatted = SakuKosFormatters.toTitleCase(trimmed);
    current.add(formatted);
    await box.put(categoriesKey, current);
    return null;
  }

  /// Menghapus kategori dari database Hive (baik kategori bawaan maupun kustom).
  /// Penolakan terjadi hanya jika kategori adalah satu-satunya yang tersisa (minimal 1 kategori tersisa).
  /// Mengembalikan [bool] true jika berhasil dihapus, false jika gagal atau ditolak.
  Future<bool> deleteCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final current = getCategories();
    // Cegah penghapusan jika hanya tersisa 1 kategori
    if (current.length <= 1) {
      return false;
    }

    final index = current.indexWhere(
      (c) => c.toLowerCase() == trimmed.toLowerCase(),
    );

    if (index != -1) {
      current.removeAt(index);
      if (current.isEmpty) {
        current.addAll(defaultCategories);
      }
      await box.put(categoriesKey, current);
      return true;
    }
    return false;
  }

  /// Notifier agar UI dapat merespon penambahan kategori secara reaktif.
  ValueListenable<Box> get listenable => box.listenable();
}
