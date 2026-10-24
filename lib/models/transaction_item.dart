/// Kategori pengeluaran & pemasukan yang tersedia di SakuKos.
abstract final class TransactionCategory {
  static const String makan = 'Makan';
  static const String kosan = 'Kosan';
  static const String nongkrong = 'Nongkrong';
  static const String transport = 'Transport';
  static const String belajar = 'Belajar';
  static const String lainnya = 'Lainnya';

  static const List<String> all = [
    makan,
    kosan,
    nongkrong,
    transport,
    belajar,
  ];
}

/// Model data transaksi untuk pengeluaran dan pemasukan SakuKos.
class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final bool isExpense;
  final DateTime date;
  final String? note;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.isExpense,
    required this.date,
    this.note,
  });

  /// Mengonversi model ke Map agar bisa disimpan langsung di Hive tanpa build_runner.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'isExpense': isExpense,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  /// Membuat instance TransactionItem dari Map data Hive.
  factory TransactionItem.fromMap(Map<dynamic, dynamic> map) {
    return TransactionItem(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      isExpense: map['isExpense'] as bool,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }

  /// Copy with helper untuk kebutuhan editing/modifikasi state.
  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    bool? isExpense,
    DateTime? date,
    String? note,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isExpense: isExpense ?? this.isExpense,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
