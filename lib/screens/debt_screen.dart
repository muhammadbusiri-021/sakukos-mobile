import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/debt_item.dart';
import '../services/debt_service.dart';

/// Halaman Catatan Talangan / Utang Teman Nongkrong (Split Bill Tracker).
class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  int _filterIndex = 0; // 0: Belum Lunas, 1: Riwayat Lunas

  Future<bool> _showDeleteConfirmDialog(
    BuildContext context,
    DebtItem item,
    SakuKosPalette colors, {
    Future<void> Function()? onConfirm,
  }) async {
    final title = item.isSettled
        ? 'Hapus Riwayat Talangan?'
        : 'Hapus Catatan Talangan?';
    final content = item.isSettled
        ? 'Riwayat bahwa ${item.friendName} telah lunas sebesar ${SakuKosFormatters.rupiah(item.amount)} akan dihapus permanen. Lanjutkan?'
        : 'Uang sebesar ${SakuKosFormatters.rupiah(item.amount)} ini belum ditandai lunas. Apakah Anda yakin ingin menghapusnya?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('cancel_delete_debt_button'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_debt_button'),
            onPressed: () async {
              if (onConfirm != null) {
                await onConfirm();
              }
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
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final service = DebtService();
    final colors = SakuKosPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListenableBuilder(
          listenable: service.listenable,
          builder: (context, child) {
            final activeDebts = service.getActiveDebts();
            final settledDebts = service.getSettledDebts();
            final totalUnsettled = service.getTotalUnsettledAmount();
            final displayedList =
                _filterIndex == 0 ? activeDebts : settledDebts;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. FIXED HEADER ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan Talangan',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jangan sampai lupa nagih teman',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('debt_theme_toggle_button'),
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: colors.textPrimary,
                          size: 22,
                        ),
                        tooltip: isDark
                            ? 'Beralih ke Mode Terang'
                            : 'Beralih ke Mode Gelap',
                        onPressed: () => themeNotifier.toggleTheme(),
                      ),
                    ],
                  ),
                ),

                // ── 2. SCROLLABLE CONTENT ────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // ── Kartu Ringkasan (Total Belum Kembali) ────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: totalUnsettled > 0
                                  ? colors.rose.withAlpha(80)
                                  : colors.emerald.withAlpha(80),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (totalUnsettled > 0
                                        ? colors.rose
                                        : colors.emerald)
                                    .withAlpha(15),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Belum Kembali',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (totalUnsettled > 0
                                              ? colors.rose
                                              : colors.emerald)
                                          .withAlpha(30),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      totalUnsettled > 0
                                          ? '${activeDebts.length} Teman'
                                          : 'Lunas Semua',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: totalUnsettled > 0
                                            ? colors.rose
                                            : colors.emerald,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                SakuKosFormatters.rupiah(totalUnsettled),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: totalUnsettled > 0
                                      ? colors.rose
                                      : colors.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Tab Filter Kecil ─────────────────────────────
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  key: const Key('debt_filter_active'),
                                  onTap: () =>
                                      setState(() => _filterIndex = 0),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _filterIndex == 0
                                          ? colors.scaffold
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: _filterIndex == 0
                                          ? Border.all(color: colors.border)
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Belum Lunas (${activeDebts.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _filterIndex == 0
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _filterIndex == 0
                                            ? colors.textPrimary
                                            : colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: GestureDetector(
                                  key: const Key('debt_filter_settled'),
                                  onTap: () =>
                                      setState(() => _filterIndex = 1),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _filterIndex == 1
                                          ? colors.scaffold
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: _filterIndex == 1
                                          ? Border.all(color: colors.border)
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Riwayat Lunas (${settledDebts.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _filterIndex == 1
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _filterIndex == 1
                                            ? colors.textPrimary
                                            : colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Daftar Kartu Talangan ────────────────────────
                        const SizedBox(height: 16),
                        if (displayedList.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 36,
                            ),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colors.emerald.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _filterIndex == 0
                                        ? Icons.verified_outlined
                                        : Icons.receipt_long_outlined,
                                    size: 38,
                                    color: colors.emerald,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _filterIndex == 0
                                      ? 'Tidak ada tagihan aktif. Semua aman!'
                                      : 'Belum ada riwayat talangan lunas',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...displayedList.map((item) {
                            final cardContent = Container(
                              key: Key('debt_card_${item.id}'),
                              padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colors.card,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colors.border,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Avatar Inisial Teman
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: (item.isSettled
                                                      ? colors.emerald
                                                      : colors.rose)
                                                  .withAlpha(30),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              item.friendName.isNotEmpty
                                                  ? item.friendName[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: item.isSettled
                                                    ? colors.emerald
                                                    : colors.rose,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Nama Teman & Keperluan
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.friendName,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: colors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.description,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: colors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  SakuKosFormatters
                                                      .indonesianDate(
                                                    item.date,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: colors.textSecondary
                                                        .withAlpha(160),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Nominal
                                          Text(
                                            SakuKosFormatters.rupiah(item.amount),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: item.isSettled
                                                  ? colors.emerald
                                                  : colors.rose,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            key: Key('delete_debt_${item.id}'),
                                            onPressed: () async {
                                              await _showDeleteConfirmDialog(
                                                context,
                                                item,
                                                colors,
                                                onConfirm: () async {
                                                  await service
                                                      .deleteDebt(item.id);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          item.isSettled
                                                              ? 'Riwayat talangan ${item.friendName} dihapus'
                                                              : 'Catatan talangan ${item.friendName} dihapus',
                                                        ),
                                                        duration:
                                                            const Duration(
                                                          seconds: 2,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              );
                                            },
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              color:
                                                  colors.rose.withAlpha(200),
                                              size: 20,
                                            ),
                                            tooltip: item.isSettled
                                                ? 'Hapus Riwayat'
                                                : 'Hapus Catatan',
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                          ),
                                          OutlinedButton(
                                            key: Key('debt_toggle_${item.id}'),
                                            onPressed: () async {
                                              await service.toggleSettleStatus(
                                                item.id,
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      item.isSettled
                                                          ? 'Status talangan ${item.friendName} dikembalikan ke belum lunas'
                                                          : 'Talangan ${item.friendName} berhasil ditandai lunas',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: item.isSettled
                                                  ? colors.textSecondary
                                                  : colors.emerald,
                                              side: BorderSide(
                                                color: item.isSettled
                                                    ? colors.border
                                                    : colors.emerald,
                                                width: 1.2,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              item.isSettled
                                                  ? 'Batal Lunas'
                                                  : 'Tandai Lunas',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: cardContent,
                            );
                          }),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
