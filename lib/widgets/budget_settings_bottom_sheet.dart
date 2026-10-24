import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../services/budget_service.dart';
import '../services/security_service.dart';

/// Menampilkan Modal Bottom Sheet untuk mengatur budget harian / bulanan mandiri.
Future<void> showBudgetSettingsBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const BudgetSettingsBottomSheet(),
  );
}

class BudgetSettingsBottomSheet extends StatefulWidget {
  const BudgetSettingsBottomSheet({super.key});

  @override
  State<BudgetSettingsBottomSheet> createState() =>
      _BudgetSettingsBottomSheetState();
}

class _BudgetSettingsBottomSheetState extends State<BudgetSettingsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  // 0: Jatah Harian Langsung, 1: Dari Uang Saku Bulanan
  int _selectedTab = 0;
  bool _isPinActive = false;
  bool _isBiometricActive = false;

  @override
  void initState() {
    super.initState();
    final currentDaily = BudgetService().getDailyBudget();
    _amountController = TextEditingController(
      text: SakuKosFormatters.rupiah(currentDaily).replaceAll('Rp ', ''),
    );
    _isPinActive = SecurityService().isPinEnabled();
    _isBiometricActive = SecurityService().isBiometricEnabled();
  }

  Future<void> _handlePinToggle(bool value) async {
    if (value) {
      await _showPinSetupDialog();
    } else {
      await SecurityService().disableSecurity();
      if (mounted) {
        setState(() {
          _isPinActive = false;
          _isBiometricActive = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kunci keamanan dinonaktifkan'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showPinSetupDialog() async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = SakuKosPalette.of(context);
            return AlertDialog(
              backgroundColor: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: colors.border),
              ),
              title: Row(
                children: [
                  Icon(Icons.pin_rounded, color: colors.emerald, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Atur PIN 6 Digit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buat 6 angka rahasia untuk mengamankan data keuangan SakuKos Anda.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PIN Baru (6 Angka)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('input_pin_field'),
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: colors.textPrimary,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        counterText: '',
                        filled: true,
                        fillColor: colors.scaffold,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colors.emerald, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Konfirmasi PIN Baru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('confirm_pin_field'),
                      controller: confirmPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: colors.textPrimary,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        counterText: '',
                        filled: true,
                        fillColor: colors.scaffold,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colors.emerald, width: 2),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.rose,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('cancel_pin_setup_button'),
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  key: const Key('save_pin_setup_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    final confirm = confirmPinController.text.trim();

                    if (pin.length != 6) {
                      setDialogState(() {
                        errorMessage = 'PIN harus terdiri dari 6 digit angka';
                      });
                      return;
                    }
                    if (pin != confirm) {
                      setDialogState(() {
                        errorMessage = 'Konfirmasi PIN tidak cocok';
                      });
                      return;
                    }

                    await SecurityService().savePin(pin);
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx, true);
                    }
                  },
                  child: const Text('Simpan PIN'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      setState(() {
        _isPinActive = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunci PIN 6 digit berhasil diaktifkan'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showChangePinDialog() async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmNewPinController = TextEditingController();
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = SakuKosPalette.of(context);
            return AlertDialog(
              backgroundColor: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: colors.border),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_reset_rounded,
                      color: colors.emerald, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Ubah PIN 6 Digit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PIN Lama',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('input_old_pin_field'),
                      controller: oldPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: colors.textPrimary,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        counterText: '',
                        filled: true,
                        fillColor: colors.scaffold,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colors.emerald, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'PIN Baru (6 Angka)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('input_new_pin_field'),
                      controller: newPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: colors.textPrimary,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        counterText: '',
                        filled: true,
                        fillColor: colors.scaffold,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colors.emerald, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Konfirmasi PIN Baru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('confirm_new_pin_field'),
                      controller: confirmNewPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: colors.textPrimary,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        counterText: '',
                        filled: true,
                        fillColor: colors.scaffold,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colors.emerald, width: 2),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.rose,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('cancel_change_pin_button'),
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  key: const Key('save_new_pin_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final oldPin = oldPinController.text.trim();
                    final newPin = newPinController.text.trim();
                    final confirm = confirmNewPinController.text.trim();

                    final secService = SecurityService();
                    if (!secService.verifyPin(oldPin)) {
                      setDialogState(() {
                        errorMessage = 'PIN lama salah';
                      });
                      return;
                    }
                    if (newPin.length != 6) {
                      setDialogState(() {
                        errorMessage = 'PIN baru harus 6 digit angka';
                      });
                      return;
                    }
                    if (newPin != confirm) {
                      setDialogState(() {
                        errorMessage = 'Konfirmasi PIN baru tidak cocok';
                      });
                      return;
                    }

                    await secService.savePin(newPin);
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx, true);
                    }
                  },
                  child: const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN 6 digit berhasil diperbarui'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleBiometricToggle(bool value) async {
    if (!_isPinActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Atur PIN terlebih dahulu untuk mengaktifkan sidik jari'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final secService = SecurityService();
    if (value) {
      final success = await secService.authenticateBiometrics(
        reason: 'Pindai sidik jari untuk mengaktifkan kunci',
        ignoreStatus: true,
      );
      if (success) {
        if (mounted) {
          setState(() {
            _isBiometricActive = true;
          });
        }
        await secService.setBiometricEnabled(true);
      } else {
        if (mounted) {
          setState(() {
            _isBiometricActive = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi sidik jari gagal atau dibatalkan'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isBiometricActive = false;
        });
      }
      await secService.setBiometricEnabled(false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int get _daysInCurrentMonth {
    final now = DateTime.now();
    return max(1, DateTime(now.year, now.month + 1, 0).day);
  }

  double get _calculatedDailyFromMonthly {
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = double.tryParse(raw) ?? 0.0;
    return parsed / _daysInCurrentMonth;
  }

  Future<void> _handleApply() async {
    if (!_formKey.currentState!.validate()) return;

    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final parsedAmount = double.tryParse(raw);

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

    final budgetService = BudgetService();
    if (_selectedTab == 0) {
      await budgetService.setDailyBudget(parsedAmount);
    } else {
      await budgetService.setMonthlyBudget(parsedAmount);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Batas harian diatur ke ${SakuKosFormatters.rupiah(budgetService.getDailyBudget())}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
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
                    'Atur Batas Budget',
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

              // ── Tab Pilihan Metode Budget ─────────────────────────────
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
                        onTap: () {
                          if (_selectedTab != 0) {
                            setState(() {
                              _selectedTab = 0;
                              _amountController.text = SakuKosFormatters.rupiah(
                                BudgetService().getDailyBudget(),
                              ).replaceAll('Rp ', '');
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? colors.emerald.withAlpha(40)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _selectedTab == 0
                                ? Border.all(color: colors.emerald)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Jatah Harian',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedTab == 0
                                  ? colors.emerald
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedTab != 1) {
                            setState(() {
                              _selectedTab = 1;
                              final currentDaily =
                                  BudgetService().getDailyBudget();
                              _amountController.text = SakuKosFormatters.rupiah(
                                currentDaily * _daysInCurrentMonth,
                              ).replaceAll('Rp ', '');
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? colors.emerald.withAlpha(40)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _selectedTab == 1
                                ? Border.all(color: colors.emerald)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Uang Saku Bulanan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedTab == 1
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
              const SizedBox(height: 18),

              // ── Input Nominal ────────────────────────────────────────
              Text(
                _selectedTab == 0
                    ? 'Target Jatah Harian (Rp)'
                    : 'Total Uang Saku Sebulan (Rp)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('budget_amount_field'),
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  const ThousandsSeparatorInputFormatter(),
                ],
                onChanged: (_) {
                  if (_selectedTab == 1) {
                    setState(() {});
                  }
                },
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
              const SizedBox(height: 12),

              // ── Kalkulasi Otomatis (jika mode bulanan) ────────────────
              if (_selectedTab == 1) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.scaffold,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: colors.emerald,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Jatahmu menjadi sekitar ${SakuKosFormatters.rupiah(_calculatedDailyFromMonthly)} / hari ($_daysInCurrentMonth hari di bulan ini).',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 6),

              // ── Seksi Keamanan ───────────────────────────────────────
              const SizedBox(height: 10),
              Divider(color: colors.border, height: 1),
              const SizedBox(height: 16),
              Text(
                'Keamanan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Tile 1: Kunci PIN (6 Digit)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.scaffold,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.emerald.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.pin_rounded,
                        color: colors.emerald,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kunci PIN (6 Digit)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Amankan data keuangan SakuKos',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isPinActive)
                      TextButton(
                        key: const Key('change_pin_button'),
                        onPressed: _showChangePinDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Ubah PIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.emerald,
                          ),
                        ),
                      ),
                    Switch(
                      key: const Key('pin_toggle_switch'),
                      value: _isPinActive,
                      onChanged: _handlePinToggle,
                      activeThumbColor: colors.emerald,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Tile 2: Buka Cepat dengan Sidik Jari
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.scaffold,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isPinActive
                            ? colors.emerald.withAlpha(25)
                            : colors.textSecondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        color: _isPinActive
                            ? colors.emerald
                            : colors.textSecondary.withAlpha(120),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kunci Sidik Jari',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isPinActive
                                  ? colors.textPrimary
                                  : colors.textSecondary.withAlpha(160),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isPinActive
                                ? 'Buka cepat dengan sensor sidik jari'
                                : 'Atur PIN terlebih dahulu',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      key: const Key('biometric_toggle_switch'),
                      value: _isPinActive && _isBiometricActive,
                      onChanged: _isPinActive ? _handleBiometricToggle : null,
                      activeThumbColor: colors.emerald,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Tombol Terapkan Budget ────────────────────────────────
              ElevatedButton(
                key: const Key('apply_budget_button'),
                onPressed: _handleApply,
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
                  'Terapkan Budget',
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
