import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sakukos/core/formatters.dart';
import 'package:sakukos/models/debt_item.dart';
import 'package:sakukos/models/transaction_item.dart';
import 'package:share_plus/share_plus.dart';

/// Layanan untuk mengekspor data transaksi dan catatan talangan ke format CSV
/// yang kompatibel penuh dengan Microsoft Excel dan Google Sheets.
class CsvExportService {
  /// Header UTF-8 Byte Order Mark (BOM) agar Excel membaca karakter dengan benar.
  static const String utf8Bom = '\uFEFF';

  /// Helper untuk meng-escape teks agar aman dari karakter koma dan tanda kutip ganda.
  static String _escape(String text) {
    return '"${text.replaceAll('"', '""')}"';
  }

  /// Format tanggal standar YYYY-MM-DD agar mudah dipilah dan diformat di spreadsheet.
  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Menghasilkan format teks CSV untuk daftar transaksi keuangan.
  String generateTransactionsCsv(List<TransactionItem> items) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln('Tanggal,Jam,Tipe,Kategori,Judul,Nominal,Catatan');

    for (final item in items) {
      final date = _formatDate(item.date);
      final time = SakuKosFormatters.time(item.date);
      final type = item.isExpense ? 'Pengeluaran' : 'Pemasukan';
      final category = _escape(item.category);
      final title = _escape(item.title);
      final amount = item.amount.toStringAsFixed(0);
      final note = _escape(item.note ?? '');

      buffer.writeln('$date,$time,$type,$category,$title,$amount,$note');
    }

    return buffer.toString();
  }

  /// Menghasilkan format teks CSV untuk daftar catatan talangan / hutang teman.
  String generateDebtsCsv(List<DebtItem> items) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln('Tanggal,Nama Teman,Keperluan,Nominal,Status');

    for (final item in items) {
      final date = _formatDate(item.date);
      final friend = _escape(item.friendName);
      final description = _escape(item.description);
      final amount = item.amount.toStringAsFixed(0);
      final status = item.isSettled ? 'Lunas' : 'Belum Lunas';

      buffer.writeln('$date,$friend,$description,$amount,$status');
    }

    return buffer.toString();
  }

  /// Menyimpan string CSV ke direktori sementara lokal lalu memicu dialog bagikan sistem.
  Future<void> exportAndShareCsv({
    required String fileName,
    required String csvContent,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(csvContent, encoding: utf8);
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'text/csv')],
      text: 'Laporan Keuangan SakuKos',
    );
  }
}
