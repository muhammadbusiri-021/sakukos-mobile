import 'dart:math';
import 'package:flutter/services.dart';

/// Helper utilitas untuk pemformatan tanggal dan mata uang Rupiah
/// tanpa ketergantungan locale eksternal (100% bebas dari LocaleDataException).
abstract final class SakuKosFormatters {
  static const List<String> dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> shortDayNames = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static const List<String> monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Format tanggal Indonesia lengkap: "Kamis, 22 Oktober 2026"
  static String indonesianDate(DateTime date) {
    final dayName = dayNames[date.weekday - 1];
    final day = date.day;
    final monthName = monthNames[date.month - 1];
    final year = date.year;
    return '$dayName, $day $monthName $year';
  }

  /// Singkatan nama hari: "Sen", "Sel", "Rab", dll.
  static String shortDayName(DateTime date) {
    return shortDayNames[date.weekday - 1];
  }

  /// Format jam dan menit: "14:05"
  static String time(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format nominal mata uang Rupiah standar bersih tanpa tanda +/-: "Rp 50.000"
  static String rupiah(num amount) {
    final absAmount = amount.abs().round();
    final formatted = absAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    return 'Rp $formatted';
  }

  /// Format teks menjadi Title Case: "makan" -> "Makan", "paket data" -> "Paket Data".
  static String toTitleCase(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

/// Custom TextInputFormatter untuk menambahkan titik pemisah ribuan otomatis saat mengetik angka nominal.
/// Contoh: '1000' -> '1.000', '150000' -> '150.000'.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Ambil hanya digit angka
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Format dengan titik pemisah ribuan
    final formatted = digitsOnly.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    // Hitung posisi kursor yang presisi agar kursor tidak melompat
    final selectionEnd = max(0, min(newValue.selection.end, newValue.text.length));
    final digitsBeforeCursor = newValue.text
        .substring(0, selectionEnd)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    var newCursorPos = 0;
    var digitCount = 0;
    while (newCursorPos < formatted.length && digitCount < digitsBeforeCursor) {
      if (RegExp(r'[0-9]').hasMatch(formatted[newCursorPos])) {
        digitCount++;
      }
      newCursorPos++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}
