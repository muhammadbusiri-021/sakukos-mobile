import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/transaction_item.dart';
import '../services/transaction_service.dart';
import 'add_transaction_bottom_sheet.dart';

/// Menampilkan Modal Bottom Sheet untuk melihat detail lengkap transaksi
/// dan menyediakan opsi untuk mengedit atau menghapusnya.
Future<void> showTransactionDetailBottomSheet(
  BuildContext context,
  TransactionItem item,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TransactionDetailBottomSheet(item: item),
  );

  if (action == 'edit' && context.mounted) {
    await showAddTransactionBottomSheet(context, initialItem: item);
  }
}

class TransactionDetailBottomSheet extends StatelessWidget {
  final TransactionItem item;

  const TransactionDetailBottomSheet({
    super.key,
    required this.item,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case TransactionCategory.makan:
        return Icons.restaurant_rounded;
      case TransactionCategory.kosan:
        return Icons.home_work_rounded;
      case TransactionCategory.nongkrong:
        return Icons.coffee_rounded;
      case TransactionCategory.transport:
        return Icons.directions_bike_rounded;
      case TransactionCategory.belajar:
        return Icons.menu_book_rounded;
      case TransactionCategory.lainnya:
        return Icons.receipt_long_rounded;
      default:
        return Icons.local_offer_outlined;
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    SakuKosPalette colors,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          'Hapus Transaksi?',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus transaksi "${item.title}" sebesar ${SakuKosFormatters.rupiah(item.amount)}?',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('cancel_delete_transaction_button'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_transaction_button'),
            onPressed: () async {
              await TransactionService().deleteTransaction(item.id);
              if (ctx.mounted) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.rose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context); // Tutup bottom sheet detail
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi "${item.title}" dihapus'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SakuKosPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = item.isExpense ? colors.rose : colors.emerald;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.border, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle Bar ─────────────────────────────────────────
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header: Ikon Kategori, Nama Kategori & Tombol Close ─
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(item.category),
                          size: 18,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Nominal Besar & Badge Tipe ─────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      SakuKosFormatters.rupiah(item.amount),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: accentColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.isExpense ? 'Pengeluaran' : 'Pemasukan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Judul Transaksi (Lengkap Tanpa Terpotong) ───────────
              Text(
                'Judul Transaksi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),

              // ── Informasi Waktu ────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${SakuKosFormatters.indonesianDate(item.date)} • ${SakuKosFormatters.time(item.date)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),

              // ── Kotak Catatan / Kalimat Asli ────────────────────────
              if (item.note != null && item.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.scaffold,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Catatan Asli',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.note!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── Tombol Aksi: Hapus & Edit Transaksi ──────────────────
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      key: const Key('detail_delete_button'),
                      onPressed: () => _handleDelete(context, colors),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: colors.rose,
                      ),
                      label: Text(
                        'Hapus',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.rose,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: colors.rose.withAlpha(120),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      key: const Key('detail_edit_button'),
                      onPressed: () => Navigator.pop(context, 'edit'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit Transaksi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.emerald,
                        foregroundColor:
                            isDark ? colors.scaffold : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
