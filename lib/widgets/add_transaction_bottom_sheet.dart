import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/transaction_item.dart';
import '../services/category_service.dart';
import '../services/smart_text_parser.dart';
import '../services/transaction_service.dart';

/// Menampilkan Modal Bottom Sheet untuk menambahkan transaksi baru dengan
/// dukungan Catat Cepat (Smart Text Parser) dan Form Manual, serta mode edit.
Future<void> showAddTransactionBottomSheet(
  BuildContext context, {
  TransactionItem? initialItem,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddTransactionBottomSheet(initialItem: initialItem),
  );
}

class AddTransactionBottomSheet extends StatefulWidget {
  final TransactionItem? initialItem;

  const AddTransactionBottomSheet({
    super.key,
    this.initialItem,
  });

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  int _selectedTabIndex = 0; // 0: Catat Cepat, 1: Form Manual

  // Controllers untuk Catat Cepat
  final _smartTextController = TextEditingController();
  ParsedTransaction? _parsedTransaction;
  ParsedTransaction? get _parsedResult => _parsedTransaction;

  bool _hasManuallySelectedCategory = false;

  // Controllers untuk Form Manual
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isExpense = true;
  String _selectedCategory = TransactionCategory.makan;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _selectedTabIndex = 1;
      _titleController.text = item.title;
      _amountController.text = const ThousandsSeparatorInputFormatter()
          .formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(text: item.amount.toInt().toString()),
          )
          .text;
      _noteController.text = item.note ?? '';
      _isExpense = item.isExpense;
      _selectedCategory = item.category;
    }
  }

  @override
  void dispose() {
    _smartTextController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
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
        return Icons.receipt_long_rounded;
      default:
        return Icons.local_offer_outlined;
    }
  }

  void _onSmartTextChanged(String text) {
    final parsed = SmartTextParser.parse(text);
    setState(() {
      _parsedTransaction = parsed;
      if (!_hasManuallySelectedCategory &&
          parsed != null &&
          parsed.category.isNotEmpty) {
        _selectedCategory = SakuKosFormatters.toTitleCase(parsed.category);
      }
    });
  }

  Future<void> _handleQuickSave() async {
    final parsed = _parsedTransaction;
    if (parsed == null || parsed.amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan nominal uangnya ya (contoh: es teh 5k)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final String finalTitle = parsed.title.trim().isNotEmpty
        ? parsed.title
        : _smartTextController.text.trim();

    final String finalCategory = _selectedCategory.trim().isNotEmpty
        ? SakuKosFormatters.toTitleCase(_selectedCategory)
        : SakuKosFormatters.toTitleCase(parsed.category);

    final newItem = TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: finalTitle.isNotEmpty ? finalTitle : 'Pengeluaran',
      amount: parsed.amount,
      category: finalCategory,
      isExpense: parsed.isExpense,
      date: DateTime.now(),
      note: _smartTextController.text.trim(),
    );

    await TransactionService().addTransaction(newItem);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleManualSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Bersihkan karakter non-digit untuk mencegah FormatException
    final rawAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final parsedAmount = double.tryParse(rawAmount);

    if (parsedAmount == null || parsedAmount <= 0) {
      final colors = SakuKosPalette.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nominal harus lebih dari 0'),
          backgroundColor: colors.rose,
        ),
      );
      return;
    }

    final initial = widget.initialItem;
    final finalCategory = SakuKosFormatters.toTitleCase(_selectedCategory);
    final transaction = TransactionItem(
      id: initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amount: parsedAmount,
      category: finalCategory,
      isExpense: _isExpense,
      date: initial?.date ?? DateTime.now(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (initial != null) {
      await TransactionService().updateTransaction(transaction);
    } else {
      await TransactionService().addTransaction(transaction);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showAddCategoryDialog(
    BuildContext context,
    SakuKosPalette colors,
  ) async {
    final controller = TextEditingController();
    String? errorMessage;

    final newCategory = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            'Tambah Kategori Baru',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('new_category_field'),
                controller: controller,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Contoh: Paket Data, Skincare',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  errorText: errorMessage,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              key: const Key('save_category_button'),
              onPressed: () async {
                final text = controller.text.trim();
                final error = await CategoryService().addCategory(text);
                if (error != null) {
                  setDialogState(() {
                    errorMessage = error;
                  });
                } else if (ctx.mounted) {
                  Navigator.pop(ctx, text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.emerald,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      final formatted = SakuKosFormatters.toTitleCase(newCategory);
      if (mounted) {
        setState(() {
          _selectedCategory = formatted;
          _hasManuallySelectedCategory = true;
        });
      }
    }
  }

  Future<void> _showDeleteCategoryDialog(
    BuildContext context,
    String category,
    SakuKosPalette colors,
  ) async {
    final categoryService = CategoryService();
    final currentCategories = categoryService.getCategories();
    if (currentCategories.length <= 1) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada satu kategori tersimpan'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          'Hapus Kategori?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          "Kategori '$category' akan dihapus dari daftar pilihan chip. Riwayat transaksi lama tetap aman.",
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('cancel_delete_category_button'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_category_button'),
            onPressed: () async {
              await categoryService.deleteCategory(category);
              if (ctx.mounted) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.rose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        setState(() {
          if (_selectedCategory == category) {
            final remaining = categoryService.getCategories();
            _selectedCategory = remaining.isNotEmpty
                ? remaining.first
                : TransactionCategory.makan;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colors = SakuKosPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.border, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Handle Bar ───────────────────────────────────────────
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

            // ── Header & Judul Modal ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialItem != null
                      ? 'Edit Transaksi'
                      : 'Catat Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
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

            // ── Tab Pilihan: Catat Cepat vs Form Manual ───────────────
            if (widget.initialItem == null) ...[
              Container(
                padding: const EdgeInsets.all(4),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: colors.scaffold,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? colors.card
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            border: _selectedTabIndex == 0
                                ? Border.all(color: colors.border)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: _selectedTabIndex == 0
                                    ? colors.emerald
                                    : colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Catat Cepat',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedTabIndex == 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _selectedTabIndex == 0
                                      ? colors.textPrimary
                                      : colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? colors.card
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            border: _selectedTabIndex == 1
                                ? Border.all(color: colors.border)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                size: 18,
                                color: _selectedTabIndex == 1
                                    ? colors.emerald
                                    : colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Form Manual',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedTabIndex == 1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _selectedTabIndex == 1
                                      ? colors.textPrimary
                                      : colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Konten Berdasarkan Tab yang Dipilih ───────────────────
            if (widget.initialItem != null || _selectedTabIndex == 1)
              _buildManualFormTab(colors, isDark)
            else
              _buildSmartInputTab(colors, isDark),
          ],
        ),
      ),
    );
  }

  /// Tampilan Tab Catat Cepat (Smart Input)
  Widget _buildSmartInputTab(SakuKosPalette colors, bool isDark) {
    final hasValidAmount = _parsedResult != null && _parsedResult!.amount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Input Bahasa Santai',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('smart_text_field'),
          controller: _smartTextController,
          minLines: 2,
          maxLines: 3,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: makan geprek mas kobis 18k atau bensin beat 25rb',
            hintStyle: TextStyle(
              color: colors.textSecondary.withAlpha(180),
              fontSize: 13,
              height: 1.4,
            ),
            filled: true,
            fillColor: colors.scaffold,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.emerald, width: 1.5),
            ),
          ),
          onChanged: _onSmartTextChanged,
        ),

        // Live Preview Card
        const SizedBox(height: 14),
        if (hasValidAmount)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.scaffold,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _parsedResult!.isExpense
                    ? colors.rose.withAlpha(80)
                    : colors.emerald.withAlpha(80),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Chip Kategori
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(_selectedCategory),
                            size: 14,
                            color: colors.emerald,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedCategory,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Indikator Pengeluaran vs Pemasukan
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (_parsedResult!.isExpense
                                ? colors.rose
                                : colors.emerald)
                            .withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _parsedResult!.isExpense ? 'Pengeluaran' : 'Pemasukan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _parsedResult!.isExpense
                              ? colors.rose
                              : colors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _parsedResult!.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  SakuKosFormatters.rupiah(_parsedResult!.amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _parsedResult!.isExpense
                        ? colors.rose
                        : colors.emerald,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.scaffold,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ketik transaksi dengan bahasa santai. Nominal, kategori, dan jenis transaksi akan terdeteksi otomatis.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // ── Pilihan Kategori (ChoiceChip Horizontal) ──────────────
        _buildCategorySelector(colors),

        const SizedBox(height: 24),
        ElevatedButton(
          key: const Key('smart_save_button'),
          onPressed: _handleQuickSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.emerald,
            foregroundColor: isDark ? colors.scaffold : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Catat Sekarang',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// Komponen Deretan Chip Pilihan Kategori (Horizontal)
  Widget _buildCategorySelector(SakuKosPalette colors) {
    final categories = CategoryService().getCategories();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...categories.map((category) {
                final isSelected =
                    _selectedCategory.toLowerCase() == category.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onLongPress: () => _showDeleteCategoryDialog(
                      context,
                      category,
                      colors,
                    ),
                    child: ChoiceChip(
                      key: Key('category_chip_$category'),
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                            _hasManuallySelectedCategory = true;
                          });
                        }
                      },
                      selectedColor: colors.emerald.withAlpha(45),
                      backgroundColor: colors.scaffold,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? colors.emerald
                            : colors.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected ? colors.emerald : colors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  key: const Key('add_category_chip'),
                  onPressed: () => _showAddCategoryDialog(context, colors),
                  avatar: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: colors.emerald,
                  ),
                  label: Text(
                    'Tambah',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.emerald,
                    ),
                  ),
                  backgroundColor: colors.scaffold,
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tampilan Tab Form Manual (Form Standar)
  Widget _buildManualFormTab(SakuKosPalette colors, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Toggle Pengeluaran vs Pemasukan ───────────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.scaffold,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExpense = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isExpense
                            ? colors.rose.withAlpha(40)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: _isExpense
                            ? Border.all(color: colors.rose)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Pengeluaran',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isExpense
                              ? colors.rose
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExpense = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isExpense
                            ? colors.emerald.withAlpha(40)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: !_isExpense
                            ? Border.all(color: colors.emerald)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Pemasukan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !_isExpense
                              ? colors.emerald
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Input Judul ──────────────────────────────────────────
          Text(
            'Nama Transaksi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('add_title_field'),
            controller: _titleController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Contoh: Nasi Padang, Laundry, Uang Saku',
              hintStyle: TextStyle(color: colors.textSecondary),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Nama transaksi wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Input Nominal ────────────────────────────────────────
          Text(
            'Nominal (Rp)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('add_amount_field'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              const ThousandsSeparatorInputFormatter(),
            ],
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                color: colors.emerald,
                fontWeight: FontWeight.w700,
              ),
              hintText: '0',
              hintStyle: TextStyle(color: colors.textSecondary),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Nominal wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Pilihan Kategori (ChoiceChip Horizontal) ──────────────
          _buildCategorySelector(colors),
          const SizedBox(height: 16),

          // ── Catatan Opsional ──────────────────────────────────────
          Text(
            'Catatan (Opsional)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _noteController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Contoh: Porsi jumbo + es teh',
              hintStyle: TextStyle(color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),

          // ── Tombol Simpan ────────────────────────────────────────
          ElevatedButton(
            key: widget.initialItem != null
                ? const Key('edit_save_button')
                : const Key('add_save_button'),
            onPressed: _handleManualSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.emerald,
              foregroundColor: isDark ? colors.scaffold : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.initialItem != null
                  ? 'Simpan Perubahan'
                  : 'Simpan Transaksi',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
