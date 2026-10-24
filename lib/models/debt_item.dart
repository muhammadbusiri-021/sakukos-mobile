/// Model data untuk mencatat uang talangan / patungan bersama teman.
class DebtItem {
  final String id;
  final String friendName;
  final String description;
  final double amount;
  final DateTime date;
  final bool isSettled;

  const DebtItem({
    required this.id,
    required this.friendName,
    required this.description,
    required this.amount,
    required this.date,
    this.isSettled = false,
  });

  /// Mengonversi objek [DebtItem] menjadi `Map<String, dynamic>` untuk disimpan ke Hive.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'friendName': friendName,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'isSettled': isSettled,
    };
  }

  /// Membuat instance [DebtItem] dari Map Hive.
  factory DebtItem.fromMap(Map<dynamic, dynamic> map) {
    return DebtItem(
      id: map['id'] as String,
      friendName: map['friendName'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      isSettled: (map['isSettled'] as bool?) ?? false,
    );
  }

  /// Membuat salinan objek dengan modifikasi atribut tertentu.
  DebtItem copyWith({
    String? id,
    String? friendName,
    String? description,
    double? amount,
    DateTime? date,
    bool? isSettled,
  }) {
    return DebtItem(
      id: id ?? this.id,
      friendName: friendName ?? this.friendName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isSettled: isSettled ?? this.isSettled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          friendName == other.friendName &&
          description == other.description &&
          amount == other.amount &&
          date.toIso8601String() == other.date.toIso8601String() &&
          isSettled == other.isSettled;

  @override
  int get hashCode => Object.hash(
        id,
        friendName,
        description,
        amount,
        date.toIso8601String(),
        isSettled,
      );

  @override
  String toString() =>
      'DebtItem(id: $id, friendName: "$friendName", description: "$description", amount: $amount, isSettled: $isSettled)';
}
