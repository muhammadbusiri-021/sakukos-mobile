import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/transaction_item.dart';
import '../services/budget_service.dart';
import '../services/transaction_service.dart';
import '../widgets/budget_settings_bottom_sheet.dart';
import '../widgets/cashflow_summary_card.dart';
import '../widgets/transaction_detail_bottom_sheet.dart';
import '../widgets/weekly_expense_chart.dart';

/// Halaman Dashboard utama SakuKos: Menampilkan header tetap (fixed header),
/// hero card jatah harian, grafik tren 7 hari, dan transaksi terkini.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final service = TransactionService();
    final budgetService = BudgetService();
    final colors = SakuKosPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            service.listenable,
            budgetService.listenable,
          ]),
          builder: (context, child) {
            final transactions = service.getAllTransactions();
            final todayExpense = service.getTodayTotalExpense();
            final monthExpense = service.getMonthTotalExpense();
            final dailyBudget = budgetService.getDailyBudget();
            final remaining = dailyBudget - todayExpense;
            final isOverbudget = remaining < 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. FIXED HEADER (Tetap diam di atas layar) ───────────
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
                              SakuKosFormatters.indonesianDate(
                                DateTime.now(),
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Halo, Selamat Datang',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('theme_toggle_button'),
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

                // ── 2. SCROLLABLE CONTENT (Area yang dapat di-scroll) ────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // ── Hero Card: Status Jatah Hari Ini ─────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isOverbudget
                                  ? colors.rose.withAlpha(80)
                                  : colors.emerald.withAlpha(80),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isOverbudget
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
                                    'Sisa Jatah Hari Ini',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isOverbudget
                                              ? colors.rose
                                              : colors.emerald)
                                          .withAlpha(30),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isOverbudget ? 'Melebihi Jatah' : 'Aman',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        height: 1.1,
                                        color: isOverbudget
                                            ? colors.rose
                                            : colors.emerald,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isOverbudget
                                    ? '-${SakuKosFormatters.rupiah(remaining.abs())}'
                                    : SakuKosFormatters.rupiah(remaining),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: isOverbudget
                                      ? colors.rose
                                      : colors.emerald,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () =>
                                    showBudgetSettingsBottomSheet(context),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Dari batas harian: ${SakuKosFormatters.rupiah(dailyBudget)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.tune_outlined,
                                        size: 14,
                                        color: colors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Divider(
                                  color: colors.border,
                                  height: 1,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pengeluaran Hari Ini',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          SakuKosFormatters.rupiah(todayExpense),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 36,
                                    color: colors.border,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pengeluaran Bulan Ini',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          SakuKosFormatters.rupiah(monthExpense),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Kartu Ringkasan Pemasukan & Saldo Kas ────────
                        const SizedBox(height: 12),
                        CashflowSummaryCard(
                          monthIncome: service.getMonthTotalIncome(),
                          totalBalance: service.getTotalBalance(),
                        ),

                        // ── Grafik Tren 7 Hari Terakhir ─────────────────
                        const SizedBox(height: 16),
                        WeeklyExpenseChart(
                          dailyBudget: dailyBudget,
                          expenses: service.getLast7DaysExpenses(),
                        ),

                        // ── Section Title: Transaksi Terkini ────────────
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transaksi Terkini',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            if (transactions.isNotEmpty)
                              Text(
                                '${transactions.length} transaksi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Daftar Transaksi / Empty State ───────────────
                        if (transactions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 32,
                            ),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colors.border,
                                style: BorderStyle.solid,
                              ),
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
                                    Icons.account_balance_wallet_outlined,
                                    size: 40,
                                    color: colors.emerald,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada transaksi hari ini',
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
                          ...transactions.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colors.border,
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  key: Key('transaction_card_${item.id}'),
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => showTransactionDetailBottomSheet(
                                    context,
                                    item,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                      // Ikon Kategori
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: item.isExpense
                                              ? colors.rose.withAlpha(30)
                                              : colors.emerald.withAlpha(30),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(item.category),
                                          size: 20,
                                          color: item.isExpense
                                              ? colors.rose
                                              : colors.emerald,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Judul & Waktu
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: colors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  item.category,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: colors.textSecondary,
                                                  ),
                                                ),
                                                Text(
                                                  ' • ',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: colors.textSecondary,
                                                  ),
                                                ),
                                                Text(
                                                  SakuKosFormatters.time(
                                                    item.date,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: colors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Nominal bersih tanpa tanda +/-
                                      Text(
                                        SakuKosFormatters.rupiah(item.amount),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: item.isExpense
                                              ? colors.rose
                                              : colors.emerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                          }),

                        // ── Bottom Spacing ekstra agar tidak tertutup FAB ─
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
