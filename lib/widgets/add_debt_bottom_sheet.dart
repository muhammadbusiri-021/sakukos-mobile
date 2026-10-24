import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/debt_item.dart';
import '../services/debt_service.dart';

/// Menampilkan modal bottom sheet untuk mencatat talangan teman baru.
Future<void> showAddDebtBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddDebtBottomSheet(),
  );
}

class AddDebtBottomSheet extends StatefulWidget {
  const AddDebtBottomSheet({super.key});

  @override
  State<AddDebtBottomSheet> createState() => _AddDebtBottomSheetState();
}

class _AddDebtBottomSheetState extends State<AddDebtBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _friendController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _friendController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

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

    final newDebt = DebtItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      friendName: _friendController.text.trim(),
      description: _descController.text.trim(),
      amount: parsedAmount,
      date: DateTime.now(),
      isSettled: false,
    );

    await DebtService().addDebt(newDebt);

    if (mounted) {
      Navigator.of(context).pop();
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
        child: Form(
          key: _formKey,
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
                    'Catat Talangan Teman',
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

              // ── Input Nama Teman ─────────────────────────────────────
              Text(
                'Nama Teman',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('debt_friend_field'),
                controller: _friendController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Contoh: Budi, Dimas, Rian',
                  hintStyle: TextStyle(color: colors.textSecondary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama teman wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Input Keperluan ──────────────────────────────────────
              Text(
                'Keperluan / Catatan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('debt_desc_field'),
                controller: _descController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Contoh: Patungan Mie Ayam, Bensin Beat',
                  hintStyle: TextStyle(color: colors.textSecondary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Keperluan talangan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Input Nominal Uang ───────────────────────────────────
              Text(
                'Nominal Talangan (Rp)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('debt_amount_field'),
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
              const SizedBox(height: 24),

              // ── Tombol Simpan ────────────────────────────────────────
              ElevatedButton(
                key: const Key('debt_save_button'),
                onPressed: _handleSave,
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
                  'Simpan Catatan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
