import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../core/theme.dart';

/// Kartu ringkasan aliran kas untuk menampilkan total pemasukan bulan ini
/// dan saldo kas bersih (total pemasukan - total pengeluaran).
class CashflowSummaryCard extends StatelessWidget {
  final double monthIncome;
  final double totalBalance;

  const CashflowSummaryCard({
    super.key,
    required this.monthIncome,
    required this.totalBalance,
  });

  @override
  Widget build(BuildContext context) {
    final colors = SakuKosPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNegative = totalBalance < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Kolom Kiri: Pemasukan Bulan Ini ─────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: colors.emerald,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pemasukan (Bulan)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  SakuKosFormatters.rupiah(monthIncome),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: colors.emerald,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Pembatas Garis Vertikal Tipis Elegan ────────────────────
          Container(
            height: 36,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: colors.border,
          ),

          // ── Kolom Kanan: Total Saldo Kas ────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 14,
                      color: isNegative ? colors.rose : colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Saldo Kas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  SakuKosFormatters.rupiah(totalBalance),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isNegative ? colors.rose : colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
