import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/transaction_item.dart';
import '../services/csv_export_service.dart';
import '../services/debt_service.dart';
import '../services/transaction_service.dart';
import '../widgets/transaction_detail_bottom_sheet.dart';

/// Halaman Tab Laporan & Riwayat Keuangan:
/// Menyediakan fitur pencarian real-time, filter kategori, ringkasan kalkulasi,
/// dan ekspor laporan ke format CSV yang kompatibel dengan Excel & Google Sheets.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makan':
        return Icons.restaurant_rounded;
      case 'kosan':
        return Icons.home_work_rounded;
      case 'nongkrong':
        return Icons.coffee_rounded;
      case 'transport':
        return Icons.directions_bike_rounded;
      case 'belajar':
        return Icons.menu_book_rounded;
      case 'lainnya':
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Future<void> _exportFilteredTransactions(
    List<TransactionItem> items,
    CsvExportService csvService,
  ) async {
    if (items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada transaksi yang cocok untuk diekspor'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final csv = csvService.generateTransactionsCsv(items);
    await csvService.exportAndShareCsv(
      fileName: 'sakukos_laporan_$dateStr.csv',
      csvContent: csv,
    );
  }

  Future<void> _exportAllDebts(
    DebtService debtService,
    CsvExportService csvService,
  ) async {
    final allDebts = debtService.getAllDebts();
    if (allDebts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada data talangan untuk diekspor'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final csv = csvService.generateDebtsCsv(allDebts);
    await csvService.exportAndShareCsv(
      fileName: 'sakukos_talangan_$dateStr.csv',
      csvContent: csv,
    );
  }

  @override
  Widget build(BuildContext context) {
    final txService = TransactionService();
    final debtService = DebtService();
    final csvService = CsvExportService();
    final colors = SakuKosPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListenableBuilder(
          listenable: txService.listenable,
          builder: (context, _) {
            final allTransactions = txService.getAllTransactions();

            // Mengambil kategori unik yang benar-benar ada di dalam transaksi (dinormalisasi ke Title Case)
            final existingCategories = allTransactions
                .map((t) => SakuKosFormatters.toTitleCase(t.category))
                .where((cat) => cat.isNotEmpty)
                .toSet()
                .toList();

            if (_selectedCategory != 'Semua' &&
                !existingCategories.any((cat) =>
                    cat.toLowerCase() == _selectedCategory.toLowerCase())) {
              _selectedCategory = 'Semua';
            }

            // ── Filter Transaksi Berdasarkan Kategori & Pencarian ────────
            final filtered = allTransactions.where((item) {
              if (_selectedCategory != 'Semua' &&
                  item.category.trim().toLowerCase() !=
                      _selectedCategory.toLowerCase()) {
                return false;
              }
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                final titleMatches = item.title.toLowerCase().contains(query);
                final noteMatches =
                    item.note != null && item.note!.toLowerCase().contains(query);
                if (!titleMatches && !noteMatches) {
                  return false;
                }
              }
              return true;
            }).toList();

            final totalNominal = filtered.fold<double>(
              0.0,
              (sum, item) => sum + item.amount,
            );

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
                              'Laporan & Riwayat',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pencarian, filter, dan ekspor data',
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
                        key: const Key('report_theme_toggle_button'),
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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 4),

                      // ── 1. Kartu Ringkasan Hasil Filter ────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menampilkan ${filtered.length} transaksi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              SakuKosFormatters.rupiah(totalNominal),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── 2. Search Bar ──────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border),
                        ),
                        child: TextField(
                          key: const Key('report_search_field'),
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.trim();
                            });
                          },
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari judul atau catatan...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary.withAlpha(160),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: colors.textSecondary,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    key: const Key('report_search_clear_button'),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: colors.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── 3. Horizontal Category Filter Chips ────────────
                      SizedBox(
                        height: 44,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // 1. Chip Pertama (DIPATENKAN): [ Semua ]
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  key: const Key('report_category_chip_Semua'),
                                  label: const Text('Semua'),
                                  selected: _selectedCategory == 'Semua',
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedCategory = 'Semua';
                                    });
                                  },
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selectedCategory == 'Semua'
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    height: 1.15,
                                    color: _selectedCategory == 'Semua'
                                        ? colors.emerald
                                        : (isDark
                                            ? colors.textSecondary
                                            : const Color(0xFF64748B)),
                                  ),
                                  backgroundColor: colors.card,
                                  selectedColor: colors.emerald.withAlpha(25),
                                  side: BorderSide(
                                    color: _selectedCategory == 'Semua'
                                        ? colors.emerald
                                        : colors.border,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  showCheckmark: false,
                                ),
                              ),

                              // 2. Chip Kategori Transaksi Riil
                              ...existingCategories.map((cat) {
                                final isSelected =
                                    _selectedCategory.toLowerCase() ==
                                        cat.toLowerCase();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    key: Key('report_category_chip_$cat'),
                                    label: Text(cat),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedCategory = cat;
                                      });
                                    },
                                    labelPadding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      height: 1.15,
                                      color: isSelected
                                          ? colors.emerald
                                          : (isDark
                                              ? colors.textSecondary
                                              : const Color(0xFF64748B)),
                                    ),
                                    backgroundColor: colors.card,
                                    selectedColor: colors.emerald.withAlpha(25),
                                    side: BorderSide(
                                      color: isSelected
                                          ? colors.emerald
                                          : colors.border,
                                      width: 1.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    showCheckmark: false,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 4. Baris Tombol Ekspor 50% - 50% Simetris ──────
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              key: const Key('export_filtered_csv_button'),
                              onPressed: () => _exportFilteredTransactions(
                                filtered,
                                csvService,
                              ),
                              icon: const Icon(
                                Icons.file_download_outlined,
                                size: 16,
                              ),
                              label: const Text(
                                'Ekspor Transaksi (.csv)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.emerald,
                                foregroundColor: isDark
                                    ? colors.scaffold
                                    : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('export_debts_csv_button'),
                              onPressed: () => _exportAllDebts(
                                debtService,
                                csvService,
                              ),
                              icon: Icon(
                                Icons.people_outline_rounded,
                                size: 16,
                                color: colors.textPrimary,
                              ),
                              label: Text(
                                'Ekspor Talangan (.csv)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors.border),
                                backgroundColor: colors.card,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Daftar Transaksi Hasil Filter ──────────────────
                      if (filtered.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 40,
                          ),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colors.textSecondary.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search_off_rounded,
                                  size: 36,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada transaksi yang cocok',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba ubah kata kunci atau pilih kategori lain',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filtered.map((item) {
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
                                key: Key('report_transaction_card_${item.id}'),
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
                                                    color:
                                                        colors.textSecondary,
                                                  ),
                                                ),
                                                Text(
                                                  ' • ',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        colors.textSecondary,
                                                  ),
                                                ),
                                                Text(
                                                  SakuKosFormatters.indonesianDate(
                                                    item.date,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        colors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Nominal bersih
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

                      // Spacing bawah
                      const SizedBox(height: 80),
                    ],
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
