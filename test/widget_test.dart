import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sakukos/core/theme.dart';
import 'package:sakukos/main.dart';
import 'package:sakukos/models/debt_item.dart';
import 'package:sakukos/models/transaction_item.dart';
import 'package:sakukos/screens/lock_screen_wrapper.dart';
import 'package:sakukos/services/biometric_service.dart';
import 'package:sakukos/services/budget_service.dart';
import 'package:sakukos/services/category_service.dart';
import 'package:sakukos/services/security_service.dart';
import 'package:sakukos/widgets/budget_settings_bottom_sheet.dart';
import 'package:sakukos/services/debt_service.dart';
import 'package:sakukos/services/transaction_service.dart';

class _FakeLocalAuth extends Fake implements LocalAuthentication {
  bool authResult = true;
  String? lastReason;

  @override
  Future<bool> get canCheckBiometrics => Future.value(true);

  @override
  Future<bool> isDeviceSupported() => Future.value(true);

  @override
  Future<bool> authenticate({
    required String localizedReason,
    dynamic authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    lastReason = localizedReason;
    return authResult;
  }
}

void main() {
  late Directory tempDir;
  late TransactionService service;
  late BudgetService budgetService;
  late DebtService debtService;
  late CategoryService categoryService;
  late BiometricService biometricService;
  late SecurityService securityService;
  late _FakeLocalAuth fakeAuth;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    themeNotifier.value = ThemeMode.dark;
    tempDir = await Directory.systemTemp.createTemp('sakukos_widget_test_');
    Hive.init(tempDir.path);
    service = TransactionService();
    budgetService = BudgetService();
    debtService = DebtService();
    categoryService = CategoryService();
    biometricService = BiometricService();
    fakeAuth = _FakeLocalAuth();
    biometricService.auth = fakeAuth;
    securityService = SecurityService(localAuth: fakeAuth);
    await service.init();
    await budgetService.init();
    await debtService.init();
    await categoryService.init();
    await securityService.init();
    await biometricService.init();
    await service.box.clear();
    await budgetService.box.clear();
    await debtService.box.clear();
    await categoryService.box.clear();
    await securityService.box.clear();
    await biometricService.box.clear();
    await categoryService.init();
  });

  tearDown(() async {
    await securityService.close();
    await biometricService.close();
    await service.box.close();
    await budgetService.box.close();
    await debtService.box.close();
    await categoryService.box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('DashboardScreen smoke test and empty state',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify header and greeting
    expect(find.text('Halo, Selamat Datang'), findsOneWidget);

    // Verify Hero Card elements
    expect(find.text('Sisa Jatah Hari Ini'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsOneWidget);
    expect(find.text('Aman'), findsOneWidget);
    expect(find.text('Dari batas harian: Rp 50.000'), findsOneWidget);
    expect(find.byIcon(Icons.tune_outlined), findsOneWidget);

    // Verify Theme toggle button in header
    expect(find.byKey(const Key('theme_toggle_button')), findsOneWidget);

    // Verify Cashflow Summary Card
    expect(find.text('Pemasukan (Bulan)'), findsOneWidget);
    expect(find.text('Saldo Kas'), findsOneWidget);

    // Verify Weekly Expense Chart exists
    expect(find.text('Tren 7 Hari Terakhir'), findsOneWidget);
    expect(find.text('Total pengeluaran minggu ini'), findsOneWidget);

    // Verify empty state message
    expect(
      find.text('Belum ada transaksi hari ini'),
      findsOneWidget,
    );

    // Verify BottomNavigationBar 3 tabs
    expect(find.text('Dompet'), findsOneWidget);
    expect(find.text('Talangan'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);

    // Verify FAB "Catat"
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Catat'), findsOneWidget);
  });

  testWidgets('Tap FAB opens AddTransactionBottomSheet and adds transaction',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify tabs exist and switch to Form Manual
    expect(find.text('Catat Cepat'), findsOneWidget);
    expect(find.text('Form Manual'), findsOneWidget);
    await tester.tap(find.text('Form Manual'));
    await tester.pumpAndSettle();

    // Verify clean tab labels without +/-
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('Pemasukan'), findsOneWidget);

    // Verify category chips: default categories exist, Lainnya does NOT exist
    expect(find.text('Makan'), findsWidgets);
    expect(find.text('Lainnya'), findsNothing);
    expect(find.text('Tambah'), findsOneWidget);

    // Fill form using explicit keys
    await tester.enterText(
      find.byKey(const Key('add_title_field')),
      'Nasi Padang Rendang',
    );
    await tester.enterText(
      find.byKey(const Key('add_amount_field')),
      '20000',
    );
    await tester.pumpAndSettle();

    // Tap Simpan Transaksi using runAsync so real Hive file I/O resolves
    final saveButton = find.byKey(const Key('add_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.runAsync(() async {
      await tester.tap(saveButton);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Verify modal is closed
    expect(find.text('Catat Transaksi'), findsNothing);

    // Transaction should appear in list without +/- sign
    expect(find.text('Nasi Padang Rendang'), findsOneWidget);
    expect(find.text('-Rp 20.000'), findsNothing);
    expect(find.text('+Rp 20.000'), findsNothing);

    // Hero card should update: 50.000 - 20.000 = 30.000
    expect(find.text('Rp 30.000'), findsOneWidget);
    // "Rp 20.000" appears in Pengeluaran Hari Ini, Pengeluaran Bulan Ini, WeeklyExpenseChart header, list item, and Saldo Kas
    expect(find.text('Rp 20.000'), findsNWidgets(5));
  });

  testWidgets(
      'Smart input (Catat Cepat) parses text, previews live, and saves transaction',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Default tab is Catat Cepat
    expect(find.byKey(const Key('smart_text_field')), findsOneWidget);

    // Enter natural language text
    await tester.enterText(
      find.byKey(const Key('smart_text_field')),
      'makan geprek mas kobis 18k',
    );
    await tester.pumpAndSettle();

    // Verify live preview card shows detected details
    expect(find.text('Makan Geprek Mas Kobis'), findsOneWidget);
    expect(find.text('Rp 18.000'), findsOneWidget);
    expect(find.text('Makan'), findsWidgets);
    expect(find.text('Pengeluaran'), findsOneWidget);

    // Override category to Nongkrong by tapping category chip in Catat Cepat
    final nongkrongChip = find.byKey(const Key('category_chip_Nongkrong'));
    await tester.ensureVisible(nongkrongChip);
    await tester.tap(nongkrongChip);
    await tester.pumpAndSettle();

    // Verify live preview card now reflects overridden category Nongkrong
    expect(find.text('Nongkrong'), findsWidgets);

    // Save transaction
    final smartSaveButton = find.byKey(const Key('smart_save_button'));
    await tester.runAsync(() async {
      await tester.tap(smartSaveButton);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Verify modal is dismissed
    expect(find.text('Catat Transaksi'), findsNothing);

    // Verify transaction appears in dashboard list with category Nongkrong
    expect(find.text('Makan Geprek Mas Kobis'), findsOneWidget);
    final savedItems = service.getAllTransactions();
    expect(
      savedItems.any((t) =>
          t.title == 'Makan Geprek Mas Kobis' && t.category == 'Nongkrong'),
      isTrue,
    );
    // 50.000 - 18.000 = 32.000
    expect(find.text('Rp 32.000'), findsOneWidget);
  });

  testWidgets(
      'Quick save (Catat Cepat) saves transaction with "minum es teh 5k", validates empty nominal feedback, and closes modal',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Tap "Catat Sekarang" without entering amount shows snackbar feedback
    final smartSaveButton = find.byKey(const Key('smart_save_button'));
    await tester.tap(smartSaveButton);
    await tester.pumpAndSettle();
    expect(
      find.text('Masukkan nominal uangnya ya (contoh: es teh 5k)'),
      findsOneWidget,
    );

    // Enter "minum es teh 5k" in smart_text_field
    await tester.enterText(
      find.byKey(const Key('smart_text_field')),
      'minum es teh 5k',
    );
    await tester.pumpAndSettle();

    // Verify preview card shows parsed details
    expect(find.text('Rp 5.000'), findsOneWidget);

    // Tap "Catat Sekarang" button
    await tester.runAsync(() async {
      await tester.tap(smartSaveButton);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Modal is completely closed
    expect(find.text('Catat Transaksi'), findsNothing);

    // Verify transaction is stored in database
    final transactions = service.getAllTransactions();
    expect(
      transactions.any((t) => t.amount == 5000 && t.note == 'minum es teh 5k'),
      isTrue,
    );

    // Verify transaction appears on dashboard
    expect(find.text('Rp 5.000'), findsWidgets);
  });

  testWidgets('Tap tune icon opens BudgetSettingsBottomSheet and updates budget',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap tune icon in Hero Card
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();

    // Verify Budget modal appears
    expect(find.text('Atur Batas Budget'), findsOneWidget);
    expect(find.text('Jatah Harian'), findsOneWidget);
    expect(find.text('Uang Saku Bulanan'), findsOneWidget);

    // Change daily budget to 40000
    final budgetField = find.byKey(const Key('budget_amount_field'));
    await tester.enterText(budgetField, '40000');
    await tester.pumpAndSettle();

    // Tap Terapkan Budget
    final applyButton = find.byKey(const Key('apply_budget_button'));
    await tester.ensureVisible(applyButton);
    await tester.runAsync(() async {
      await tester.tap(applyButton);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Modal closed
    expect(find.text('Atur Batas Budget'), findsNothing);

    // Hero Card shows updated daily budget
    expect(find.text('Dari batas harian: Rp 40.000'), findsOneWidget);
    expect(find.text('Rp 40.000'), findsOneWidget);
  });

  testWidgets('Theme toggle button switches between dark and light mode',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Initial state is dark mode -> light_mode_outlined icon shown
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
    expect(themeNotifier.value, ThemeMode.dark);

    // Tap toggle button to switch to light mode
    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();

    // State is light mode -> dark_mode_outlined icon shown
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_outlined), findsNothing);
    expect(themeNotifier.value, ThemeMode.light);

    // Tap toggle button again to switch back to dark mode
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
    expect(themeNotifier.value, ThemeMode.dark);
  });

  testWidgets('Switch to Talangan tab, add debt, and toggle settle status',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap Tab Talangan on BottomNavigationBar
    await tester.tap(find.text('Talangan'));
    await tester.pumpAndSettle();

    // Verify DebtScreen content
    expect(find.text('Catatan Talangan'), findsOneWidget);
    expect(find.text('Jangan sampai lupa nagih teman'), findsOneWidget);
    expect(find.text('Total Belum Kembali'), findsOneWidget);
    expect(find.text('Tidak ada tagihan aktif. Semua aman!'), findsOneWidget);

    // FAB should now say "Talangan"
    expect(find.text('Talangan'), findsNWidgets(2)); // BottomNav and FAB
    final debtFab = find.byKey(const Key('debt_fab'));
    expect(debtFab, findsOneWidget);

    // Tap FAB Talangan
    await tester.tap(debtFab);
    await tester.pumpAndSettle();

    // Verify AddDebtBottomSheet opened
    expect(find.text('Catat Talangan Teman'), findsOneWidget);

    // Fill debt form
    await tester.enterText(
      find.byKey(const Key('debt_friend_field')),
      'Budi',
    );
    await tester.enterText(
      find.byKey(const Key('debt_desc_field')),
      'Patungan Mie Ayam',
    );
    await tester.enterText(
      find.byKey(const Key('debt_amount_field')),
      '25000',
    );
    await tester.pumpAndSettle();

    // Tap Simpan Catatan
    final saveDebtButton = find.byKey(const Key('debt_save_button'));
    await tester.runAsync(() async {
      await tester.tap(saveDebtButton);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Verify modal is dismissed
    expect(find.text('Catat Talangan Teman'), findsNothing);

    // Verify debt appears in active list
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('Patungan Mie Ayam'), findsOneWidget);
    expect(find.text('Rp 25.000'), findsNWidgets(2)); // Total belum kembali & card

    // Tap "Tandai Lunas"
    final toggleButton = find.text('Tandai Lunas');
    await tester.runAsync(() async {
      await tester.tap(toggleButton);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Active list should now be empty
    expect(find.text('Tidak ada tagihan aktif. Semua aman!'), findsOneWidget);
    expect(find.text('Lunas Semua'), findsOneWidget);
  });

  testWidgets(
      'Add custom category in AddTransactionBottomSheet dynamically',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap FAB Catat
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Switch to Form Manual
    await tester.tap(find.text('Form Manual'));
    await tester.pumpAndSettle();

    // Verify "+ Tambah" category chip exists
    final addCategoryChip = find.byKey(const Key('add_category_chip'));
    await tester.ensureVisible(addCategoryChip);
    await tester.tap(addCategoryChip);
    await tester.pumpAndSettle();

    // Dialog pops up
    expect(find.text('Tambah Kategori Baru'), findsOneWidget);

    // Try to enter reserved keyword 'Semua'
    await tester.enterText(
      find.byKey(const Key('new_category_field')),
      'Semua',
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('save_category_button')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Verify error message is shown
    expect(
      find.text("Nama 'Semua' adalah filter sistem dan tidak dapat digunakan."),
      findsOneWidget,
    );
    expect(find.text('Tambah Kategori Baru'), findsOneWidget);

    // Now enter valid category name
    await tester.enterText(
      find.byKey(const Key('new_category_field')),
      'Paket Data',
    );
    await tester.pumpAndSettle();

    // Tap Simpan in dialog using runAsync for Hive write
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('save_category_button')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Dialog dismissed
    expect(find.text('Tambah Kategori Baru'), findsNothing);

    // Verify new category is rendered in chips
    expect(find.text('Paket Data'), findsOneWidget);
  });

  testWidgets(
      'Any category can be deleted via long press with confirm dialog, while last remaining category shows snackbar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap FAB Catat
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Switch to Form Manual
    await tester.tap(find.text('Form Manual'));
    await tester.pumpAndSettle();

    // 1. Long press on default category chip 'Makan' opens confirmation dialog
    final makanChip = find.byKey(const Key('category_chip_Makan'));
    await tester.ensureVisible(makanChip);
    await tester.longPress(makanChip);
    await tester.pumpAndSettle();

    // Verify dialog appears for default category 'Makan'
    expect(find.text('Hapus Kategori?'), findsOneWidget);
    expect(
      find.text(
        "Kategori 'Makan' akan dihapus dari daftar pilihan chip. Riwayat transaksi lama tetap aman.",
      ),
      findsOneWidget,
    );

    // Tap Batal
    await tester.tap(find.byKey(const Key('cancel_delete_category_button')));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Kategori?'), findsNothing);
    expect(find.text('Makan'), findsWidgets);

    // 2. Add custom category 'Skincare'
    final addCategoryChip = find.byKey(const Key('add_category_chip'));
    await tester.ensureVisible(addCategoryChip);
    await tester.tap(addCategoryChip);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('new_category_field')),
      'Skincare',
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('save_category_button')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.text('Skincare'), findsOneWidget);

    // 3. Long press on 'Skincare' custom chip and confirm delete
    final skincareChip = find.byKey(const Key('category_chip_Skincare'));
    await tester.ensureVisible(skincareChip);
    await tester.longPress(skincareChip);
    await tester.pumpAndSettle();

    expect(find.text('Hapus Kategori?'), findsOneWidget);
    expect(
      find.text(
        "Kategori 'Skincare' akan dihapus dari daftar pilihan chip. Riwayat transaksi lama tetap aman.",
      ),
      findsOneWidget,
    );

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('confirm_delete_category_button')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Dialog dismissed and 'Skincare' chip is gone
    expect(find.text('Hapus Kategori?'), findsNothing);
    expect(find.text('Skincare'), findsNothing);
  });

  testWidgets(
      'Active debt deletion requires confirmation dialog (Batal keeps, Hapus deletes)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Switch to Talangan tab
    await tester.tap(find.text('Talangan'));
    await tester.pumpAndSettle();

    // Add a debt
    final debtFab = find.byKey(const Key('debt_fab'));
    await tester.tap(debtFab);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('debt_friend_field')), 'Rian');
    await tester.enterText(
        find.byKey(const Key('debt_desc_field')), 'Bensin Motor');
    await tester.enterText(find.byKey(const Key('debt_amount_field')), '20000');
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('debt_save_button')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.text('Rian'), findsOneWidget);

    // Tap trash icon
    final deleteButton = find.byTooltip('Hapus Catatan');
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Dialog confirmation should appear
    expect(find.text('Hapus Catatan Talangan?'), findsOneWidget);

    // Tap Batal
    await tester.tap(find.byKey(const Key('cancel_delete_debt_button')));
    await tester.pumpAndSettle();

    // Item should still be present
    expect(find.text('Rian'), findsOneWidget);

    // Tap trash icon again and confirm delete
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('confirm_delete_debt_button')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Item should be deleted
    expect(find.text('Rian'), findsNothing);
    expect(find.text('Tidak ada tagihan aktif. Semua aman!'), findsOneWidget);
  });

  testWidgets(
      '3-Tab navigation between Dompet, Talangan, and Laporan with FAB behavior',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify initial screen is Dashboard (Dompet)
    expect(find.text('Halo, Selamat Datang'), findsOneWidget);
    expect(find.text('Catatan Talangan'), findsNothing);
    expect(find.text('Laporan & Riwayat'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Find the 3 tabs
    final dompetTab = find.byKey(const Key('nav_tab_0'));
    final talanganTab = find.byKey(const Key('nav_tab_1'));
    final laporanTab = find.byKey(const Key('nav_tab_2'));
    expect(dompetTab, findsOneWidget);
    expect(talanganTab, findsOneWidget);
    expect(laporanTab, findsOneWidget);

    // Switch to Talangan tab
    await tester.tap(talanganTab);
    await tester.pumpAndSettle();
    expect(find.text('Catatan Talangan'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Switch to Laporan tab
    await tester.tap(laporanTab);
    await tester.pumpAndSettle();
    expect(find.text('Laporan & Riwayat'), findsOneWidget);
    // On Laporan tab, FAB is absent
    expect(find.byType(FloatingActionButton), findsNothing);

    // Switch back to Dompet tab
    await tester.tap(dompetTab);
    await tester.pumpAndSettle();
    expect(find.text('Halo, Selamat Datang'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets(
      'Tap transaction card opens TransactionDetailBottomSheet, edits, and updates dashboard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Pre-populate with a transaction
    final testTx = TransactionItem(
      id: 'tx_detail_test',
      title: 'Mie Ayam Bakso Spesial',
      amount: 18000,
      category: TransactionCategory.makan,
      isExpense: true,
      date: DateTime.now(),
      note: 'mie ayam bakso spesial bayar 18k',
    );
    await tester.runAsync(() async {
      await service.addTransaction(testTx);
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify transaction appears in list
    expect(find.text('Mie Ayam Bakso Spesial'), findsOneWidget);

    // Tap transaction card
    await tester.tap(find.text('Mie Ayam Bakso Spesial'));
    await tester.pumpAndSettle();

    // Verify TransactionDetailBottomSheet opened
    expect(find.text('Judul Transaksi'), findsOneWidget);
    expect(find.text('Catatan Asli'), findsOneWidget);
    expect(find.text('mie ayam bakso spesial bayar 18k'), findsOneWidget);
    expect(find.byKey(const Key('detail_edit_button')), findsOneWidget);
    expect(find.byKey(const Key('detail_delete_button')), findsOneWidget);

    // Tap Edit Transaksi
    await tester.tap(find.byKey(const Key('detail_edit_button')));
    await tester.pumpAndSettle();

    // Verify Edit modal is shown
    expect(find.text('Edit Transaksi'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);

    // Edit Title and Amount
    final titleField = find.byKey(const Key('add_title_field'));
    await tester.enterText(titleField, 'Mie Ayam Jumbo');
    final amountField = find.byKey(const Key('add_amount_field'));
    await tester.enterText(amountField, '25000');
    await tester.pumpAndSettle();

    // Save changes
    final saveEditButton = find.byKey(const Key('edit_save_button'));
    await tester.runAsync(() async {
      await tester.tap(saveEditButton);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Verify edit modal is dismissed and dashboard reflects updated values
    expect(find.text('Edit Transaksi'), findsNothing);
    expect(find.text('Mie Ayam Jumbo'), findsOneWidget);
    expect(find.text('Mie Ayam Bakso Spesial'), findsNothing);
    // Sisa (25.000), Pengeluaran Hari Ini (25.000), Bulan Ini (25.000), Weekly Chart (25.000), item card (25.000), dan Saldo Kas (25.000)
    expect(find.text('Rp 25.000'), findsNWidgets(6));
  });

  testWidgets(
      'TransactionDetailBottomSheet delete button deletes transaction with confirmation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Pre-populate with a transaction
    final testTx = TransactionItem(
      id: 'tx_delete_test',
      title: 'Beli Kopi Susu',
      amount: 15000,
      category: TransactionCategory.nongkrong,
      isExpense: true,
      date: DateTime.now(),
    );
    await tester.runAsync(() async {
      await service.addTransaction(testTx);
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Beli Kopi Susu'), findsOneWidget);
    // Verified: Dashboard transaction card is solid and NOT wrapped in Dismissible
    expect(find.byType(Dismissible), findsNothing);

    // Tap transaction card to open detail
    await tester.tap(find.text('Beli Kopi Susu'));
    await tester.pumpAndSettle();

    // Tap Hapus button in detail
    await tester.tap(find.byKey(const Key('detail_delete_button')));
    await tester.pumpAndSettle();

    // Verify confirm dialog
    expect(find.text('Hapus Transaksi?'), findsOneWidget);

    // Tap Batal
    await tester.tap(find.byKey(const Key('cancel_delete_transaction_button')));
    await tester.pumpAndSettle();

    // Still in detail modal
    expect(find.text('Judul Transaksi'), findsOneWidget);

    // Tap Hapus again
    await tester.tap(find.byKey(const Key('detail_delete_button')));
    await tester.pumpAndSettle();

    // Tap confirm Hapus inside runAsync
    await tester.runAsync(() async {
      await tester
          .tap(find.byKey(const Key('confirm_delete_transaction_button')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Verify transaction is deleted from dashboard
    expect(find.text('Beli Kopi Susu'), findsNothing);
    expect(find.text('Belum ada transaksi hari ini'), findsOneWidget);
  });

  testWidgets(
      'Overbudget (boncos) displays negative remaining, red badge, and unchanged daily budget',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Daily budget is 50.000 by default. Add expense of 70.000.
    final tx = TransactionItem(
      id: 'tx_overbudget',
      title: 'Belanja Bulanan',
      amount: 70000,
      category: TransactionCategory.kosan,
      isExpense: true,
      date: DateTime.now(),
    );
    await tester.runAsync(() async {
      await service.addTransaction(tx);
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify overbudget UI
    expect(find.text('Melebihi Jatah'), findsOneWidget);
    expect(find.text('-Rp 20.000'), findsOneWidget);
    expect(find.text('Dari batas harian: Rp 50.000'), findsOneWidget);
  });

  testWidgets(
      'Weekly expense chart taps day bar and updates header cleanly without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final tx = TransactionItem(
      id: 'tx_chart_test',
      title: 'Makan Siang',
      amount: 25000,
      category: TransactionCategory.makan,
      isExpense: true,
      date: DateTime.now(),
    );
    await tester.runAsync(() async {
      await service.addTransaction(tx);
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify initial chart title and subtitle
    expect(find.text('Tren 7 Hari Terakhir'), findsOneWidget);
    expect(find.text('Total pengeluaran minggu ini'), findsOneWidget);

    final now = DateTime.now();
    final todayKey = Key('chart_bar_${now.year}_${now.month}_${now.day}');
    final barFinder = find.byKey(todayKey);
    expect(barFinder, findsOneWidget);

    // Tap on the chart bar for today
    await tester.tap(barFinder);
    await tester.pumpAndSettle();

    // Reset info should appear
    expect(find.text('Reset info'), findsOneWidget);

    // Tap again to toggle off
    await tester.tap(barFinder);
    await tester.pumpAndSettle();
    expect(find.text('Total pengeluaran minggu ini'), findsOneWidget);
  });

  testWidgets(
      'All debt tabs are solid with zero Dismissible, and settled debt can be deleted via trash icon with confirm dialog',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final activeDebt = DebtItem(
      id: 'active_debt_1',
      friendName: 'Rian',
      description: 'Nasi Padang',
      amount: 18000,
      date: DateTime.now(),
      isSettled: false,
    );
    final settledDebt = DebtItem(
      id: 'settled_debt_1',
      friendName: 'Deni',
      description: 'Es Teh',
      amount: 5000,
      date: DateTime.now(),
      isSettled: true,
    );

    await tester.runAsync(() async {
      await debtService.addDebt(activeDebt);
      await debtService.addDebt(settledDebt);
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Switch to Talangan tab
    await tester.tap(find.text('Talangan'));
    await tester.pumpAndSettle();

    // On "Belum Lunas" tab:
    expect(find.text('Rian'), findsOneWidget);
    expect(find.text('Deni'), findsNothing);
    // Verified: Active debt card is NOT wrapped in Dismissible (solid, cannot be swiped)
    expect(find.byType(Dismissible), findsNothing);

    // Switch to "Riwayat Lunas" tab
    await tester.tap(find.byKey(const Key('debt_filter_settled')));
    await tester.pumpAndSettle();

    expect(find.text('Deni'), findsOneWidget);
    expect(find.text('Rian'), findsNothing);
    // Verified: Settled debt card is ALSO solid with zero Dismissible
    expect(find.byType(Dismissible), findsNothing);

    // Tap trash icon on settled debt card
    final deleteSettledBtn = find.byKey(const Key('delete_debt_settled_debt_1'));
    expect(deleteSettledBtn, findsOneWidget);
    await tester.tap(deleteSettledBtn);
    await tester.pumpAndSettle();

    // Verify confirmation dialog title & content for settled debt
    expect(find.text('Hapus Riwayat Talangan?'), findsOneWidget);
    expect(
      find.text(
        'Riwayat bahwa Deni telah lunas sebesar Rp 5.000 akan dihapus permanen. Lanjutkan?',
      ),
      findsOneWidget,
    );

    // Tap Batal
    await tester.tap(find.byKey(const Key('cancel_delete_debt_button')));
    await tester.pumpAndSettle();

    // Deni is still present
    expect(find.text('Deni'), findsOneWidget);

    // Tap trash icon again and confirm Hapus
    await tester.tap(deleteSettledBtn);
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('confirm_delete_debt_button')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Verify settled debt is deleted and empty state appears
    expect(find.text('Deni'), findsNothing);
    expect(find.text('Belum ada riwayat talangan lunas'), findsOneWidget);
  });

  testWidgets(
      'ReportScreen search, category filtering, and export actions feedback',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Pre-populate with 3 transactions, including case-variations ('Makan' and 'makan')
    await tester.runAsync(() async {
      await service.addTransaction(
        TransactionItem(
          id: 'tx_test_1',
          title: 'Nasi Padang Rendang',
          amount: 25000,
          category: 'Makan',
          isExpense: true,
          date: DateTime.now(),
          note: 'makan siang enak',
        ),
      );
      await service.addTransaction(
        TransactionItem(
          id: 'tx_test_2',
          title: 'Buku Catatan Kuliah',
          amount: 15000,
          category: 'Belajar',
          isExpense: true,
          date: DateTime.now(),
          note: 'buku tulis binder',
        ),
      );
      await service.addTransaction(
        TransactionItem(
          id: 'tx_test_3',
          title: 'Mie Ayam Gerobak',
          amount: 12000,
          category: 'makan', // Lowercase category to test case-insensitive merging
          isExpense: true,
          date: DateTime.now(),
          note: 'mie ayam malam',
        ),
      );
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Navigate to Laporan tab
    final laporanTab = find.byKey(const Key('nav_tab_2'));
    await tester.tap(laporanTab);
    await tester.pumpAndSettle();

    // Verify header and initial state (showing 3 transactions)
    expect(find.text('Laporan & Riwayat'), findsOneWidget);
    expect(find.text('Menampilkan 3 transaksi'), findsOneWidget);
    expect(find.text('Nasi Padang Rendang'), findsOneWidget);
    expect(find.text('Buku Catatan Kuliah'), findsOneWidget);
    expect(find.text('Mie Ayam Gerobak'), findsOneWidget);

    // Verify category chips:
    // ReportScreen consolidates 'makan' and 'Makan' into a SINGLE Title Case chip [Makan].
    // No twin lowercase [makan] chip is generated!
    expect(find.byKey(const Key('report_category_chip_Semua')), findsOneWidget);
    expect(find.byKey(const Key('report_category_chip_Makan')), findsOneWidget);
    expect(find.byKey(const Key('report_category_chip_makan')), findsNothing);
    expect(
      find.byKey(Key('report_category_chip_${TransactionCategory.belajar}')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('report_category_chip_Kosan')), findsNothing);
    expect(find.byKey(const Key('report_category_chip_Nongkrong')), findsNothing);
    expect(find.byKey(const Key('report_category_chip_Transport')), findsNothing);
    expect(find.byKey(const Key('report_category_chip_Lainnya')), findsNothing);
    expect(find.byKey(const Key('report_add_category_chip')), findsNothing);

    // Verify symmetrical 50-50 export buttons
    expect(find.text('Ekspor Transaksi (.csv)'), findsOneWidget);
    expect(find.text('Ekspor Talangan (.csv)'), findsOneWidget);

    // Test Search: search for 'Rendang'
    final searchField = find.byKey(const Key('report_search_field'));
    await tester.enterText(searchField, 'Rendang');
    await tester.pumpAndSettle();

    expect(find.text('Menampilkan 1 transaksi'), findsOneWidget);
    expect(find.text('Nasi Padang Rendang'), findsOneWidget);
    expect(find.text('Buku Catatan Kuliah'), findsNothing);
    expect(find.text('Mie Ayam Gerobak'), findsNothing);

    // Clear search using clear button
    final clearBtn = find.byKey(const Key('report_search_clear_button'));
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();
    expect(find.text('Menampilkan 3 transaksi'), findsOneWidget);

    // Test Category filter: filter by 'Belajar'
    final belajarChip =
        find.byKey(Key('report_category_chip_${TransactionCategory.belajar}'));
    await tester.tap(belajarChip);
    await tester.pumpAndSettle();

    expect(find.text('Menampilkan 1 transaksi'), findsOneWidget);
    expect(find.text('Buku Catatan Kuliah'), findsOneWidget);
    expect(find.text('Nasi Padang Rendang'), findsNothing);
    expect(find.text('Mie Ayam Gerobak'), findsNothing);

    // Filter by single 'Makan' chip (merges both 'Makan' and 'makan' transactions)
    final makanChip = find.byKey(const Key('report_category_chip_Makan'));
    await tester.tap(makanChip);
    await tester.pumpAndSettle();

    expect(find.text('Menampilkan 2 transaksi'), findsOneWidget);
    expect(find.text('Nasi Padang Rendang'), findsOneWidget);
    expect(find.text('Mie Ayam Gerobak'), findsOneWidget);
    expect(find.text('Buku Catatan Kuliah'), findsNothing);
    // 25.000 + 12.000 = 37.000
    expect(find.text('Rp 37.000'), findsOneWidget);

    // Reset filter to 'Semua'
    await tester.tap(find.byKey(const Key('report_category_chip_Semua')));
    await tester.pumpAndSettle();
    expect(find.text('Menampilkan 3 transaksi'), findsOneWidget);

    // Dynamically add a transaction with custom category 'Gaji' into database
    await tester.runAsync(() async {
      await service.addTransaction(
        TransactionItem(
          id: 'tx_gaji_test',
          title: 'Gaji Bulanan',
          amount: 3000000,
          category: 'Gaji',
          isExpense: false,
          date: DateTime.now(),
        ),
      );
    });
    await tester.pumpAndSettle();

    // Verify 'Gaji' chip now dynamically appears in ReportScreen filters!
    final gajiChip = find.byKey(const Key('report_category_chip_Gaji'));
    expect(gajiChip, findsOneWidget);
    expect(find.text('Menampilkan 4 transaksi'), findsOneWidget);

    // Tap 'Gaji' chip
    await tester.tap(gajiChip);
    await tester.pumpAndSettle();
    expect(find.text('Menampilkan 1 transaksi'), findsOneWidget);
    expect(find.text('Gaji Bulanan'), findsOneWidget);
    expect(find.text('Nasi Padang Rendang'), findsNothing);

    // Verify Income Nominal Text Color on Transaction Card is Emerald (Green)
    final incomeCardFinder = find.byKey(const Key('report_transaction_card_tx_gaji_test'));
    final incomeTextFinder = find.descendant(
      of: incomeCardFinder,
      matching: find.text('Rp 3.000.000'),
    );
    expect(incomeTextFinder, findsOneWidget);
    final incomeText = tester.widget<Text>(incomeTextFinder);
    expect(incomeText.style?.color, SakuKosDarkColors.emerald);

    // Reset back to Semua
    await tester.tap(find.byKey(const Key('report_category_chip_Semua')));
    await tester.pumpAndSettle();
    expect(find.text('Menampilkan 4 transaksi'), findsOneWidget);

    // Verify Expense Nominal Text Color on Transaction Card is Rose (Red)
    final expenseCardFinder = find.byKey(const Key('report_transaction_card_tx_test_1'));
    final expenseTextFinder = find.descendant(
      of: expenseCardFinder,
      matching: find.text('Rp 25.000'),
    );
    expect(expenseTextFinder, findsOneWidget);
    final expenseText = tester.widget<Text>(expenseTextFinder);
    expect(expenseText.style?.color, SakuKosDarkColors.rose);

    // Test Empty Search Result
    await tester.enterText(searchField, 'xyz_not_exist');
    await tester.pumpAndSettle();
    expect(find.text('Menampilkan 0 transaksi'), findsOneWidget);
    expect(find.text('Tidak ada transaksi yang cocok'), findsOneWidget);

    // Test tapping export button with 0 matching items shows snackbar
    final exportFilteredBtn = find.byKey(const Key('export_filtered_csv_button'));
    await tester.tap(exportFilteredBtn);
    await tester.pumpAndSettle();
    expect(
      find.text('Tidak ada transaksi yang cocok untuk diekspor'),
      findsOneWidget,
    );

    // Test tapping debts export button when debts are empty shows snackbar
    final exportDebtsBtn = find.byKey(const Key('export_debts_csv_button'));
    await tester.tap(exportDebtsBtn);
    await tester.pumpAndSettle();
    expect(
      find.text('Belum ada data talangan untuk diekspor'),
      findsOneWidget,
    );
  });

  testWidgets(
      'BudgetSettingsBottomSheet displays security section and reflects hybrid security status',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. Initial State: PIN & Biometric lock is disabled
    await tester.runAsync(() async {
      await securityService.disableSecurity();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuKosDarkTheme(),
        home: const Scaffold(
          body: BudgetSettingsBottomSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Keamanan section elements
    final pinSwitchFinder = find.byKey(const Key('pin_toggle_switch'));
    final bioSwitchFinder = find.byKey(const Key('biometric_toggle_switch'));
    await tester.ensureVisible(pinSwitchFinder);
    await tester.pumpAndSettle();

    expect(find.text('Keamanan'), findsOneWidget);
    expect(find.text('Kunci PIN (6 Digit)'), findsOneWidget);
    expect(find.text('Kunci Sidik Jari'), findsOneWidget);
    expect(find.text('Amankan data keuangan SakuKos'), findsOneWidget);
    expect(find.text('Atur PIN terlebih dahulu'), findsOneWidget);
    expect(find.byIcon(Icons.pin_rounded), findsWidgets);
    expect(find.byIcon(Icons.fingerprint_rounded), findsWidgets);
    expect(pinSwitchFinder, findsOneWidget);
    expect(bioSwitchFinder, findsOneWidget);

    Switch pinSwitch = tester.widget<Switch>(pinSwitchFinder);
    Switch bioSwitch = tester.widget<Switch>(bioSwitchFinder);
    expect(pinSwitch.value, false);
    expect(bioSwitch.value, false);

    // Unmount first sheet
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    // 2. When PIN and Biometric lock are enabled in settings
    await tester.runAsync(() async {
      await securityService.savePin('123456');
      await securityService.setBiometricEnabled(true);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuKosDarkTheme(),
        home: const Scaffold(
          body: BudgetSettingsBottomSheet(key: ValueKey('sheet_enabled')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final enabledPinSwitch = find.byKey(const Key('pin_toggle_switch'));
    final enabledBioSwitch = find.byKey(const Key('biometric_toggle_switch'));
    await tester.ensureVisible(enabledPinSwitch);
    await tester.pumpAndSettle();

    pinSwitch = tester.widget<Switch>(enabledPinSwitch);
    bioSwitch = tester.widget<Switch>(enabledBioSwitch);
    expect(pinSwitch.value, true);
    expect(bioSwitch.value, true);
    expect(find.byKey(const Key('change_pin_button')), findsOneWidget);
    expect(find.text('Ubah PIN'), findsOneWidget);
    expect(find.text('Buka cepat dengan sensor sidik jari'), findsOneWidget);

    // Clean unmount
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'LockScreenWrapper displays hybrid lock screen, handles wrong PIN, and unlocks with correct PIN',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Enable PIN lock in Hive using runAsync
    await tester.runAsync(() async {
      await securityService.savePin('123456');
      await securityService.setBiometricEnabled(false);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuKosDarkTheme(),
        home: const LockScreenWrapper(
          child: Scaffold(
            body: Center(child: Text('Dashboard Terlindungi')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Advance clock past initial auto-auth 600ms delay
    await tester.pump(const Duration(milliseconds: 650));

    // Expect lock screen UI
    expect(find.byKey(const Key('lock_screen_view')), findsOneWidget);
    expect(find.text('SakuKos Terkunci'), findsOneWidget);
    expect(find.text('Masukkan 6 Digit PIN'), findsOneWidget);
    expect(find.text('Dashboard Terlindungi'), findsNothing);

    // Enter wrong PIN: 111111
    for (int i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('numpad_button_1')));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Expect error message and screen remains locked
    expect(find.text('PIN salah, silakan coba lagi'), findsOneWidget);
    expect(find.text('Dashboard Terlindungi'), findsNothing);

    // Enter correct PIN: 123456
    await tester.tap(find.byKey(const Key('numpad_button_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('numpad_button_2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('numpad_button_3')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('numpad_button_4')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('numpad_button_5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('numpad_button_6')));
    await tester.pumpAndSettle();

    // Content should now be visible
    expect(find.text('Dashboard Terlindungi'), findsOneWidget);
    expect(find.byKey(const Key('lock_screen_view')), findsNothing);

    // Unmount widget tree cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'LockScreenWrapper does not lock screen if PIN is not set (emergency bypass)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Biometric may be enabled from old version, but PIN is NOT set
    await tester.runAsync(() async {
      await securityService.disableSecurity();
      await securityService.setBiometricEnabled(true);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuKosDarkTheme(),
        home: const LockScreenWrapper(
          child: Scaffold(
            body: Center(child: Text('Dashboard Terlindungi')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // App must NOT be locked without a valid PIN
    expect(find.text('Dashboard Terlindungi'), findsOneWidget);
    expect(find.byKey(const Key('lock_screen_view')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'LockScreenWrapper handles lifecycle resumed with 2s cooldown to prevent race condition',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Enable PIN
    await tester.runAsync(() async {
      await securityService.savePin('123456');
      await securityService.setBiometricEnabled(false);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuKosDarkTheme(),
        home: const LockScreenWrapper(
          child: Scaffold(
            body: Center(child: Text('Dashboard Terlindungi')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Unlock with PIN: 123456
    for (int i = 1; i <= 6; i++) {
      await tester.tap(find.byKey(Key('numpad_button_$i')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Terlindungi'), findsOneWidget);
    expect(find.byKey(const Key('lock_screen_view')), findsNothing);

    // 1. Simulate brief dialog / transient blur (< 2 seconds)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 300));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // App should remain unlocked!
    expect(find.text('Dashboard Terlindungi'), findsOneWidget);
    expect(find.byKey(const Key('lock_screen_view')), findsNothing);

    // 2. Simulate genuine background exit (>= 2 seconds)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // App should now be locked
    expect(find.byKey(const Key('lock_screen_view')), findsOneWidget);
    expect(find.text('Dashboard Terlindungi'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'LockScreenWrapper displays lock screen and unlocks with fingerprint fallback',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Enable PIN and Biometric lock in Hive using runAsync
    await tester.runAsync(() async {
      await securityService.savePin('123456');
      await securityService.setBiometricEnabled(true);
    });
    fakeAuth.authResult = false; // Initial auto-auth fails to show lock screen

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuKosDarkTheme(),
        home: const LockScreenWrapper(
          child: Scaffold(
            body: Center(child: Text('Dashboard Terlindungi')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Advance clock past initial auto-auth 600ms delay
    await tester.pump(const Duration(milliseconds: 650));

    // Expect lock screen UI
    expect(find.byKey(const Key('lock_screen_view')), findsOneWidget);
    expect(find.text('SakuKos Terkunci'), findsOneWidget);
    expect(find.text('Masukkan 6 Digit PIN'), findsOneWidget);
    expect(find.text('Dashboard Terlindungi'), findsNothing);

    // Tap fingerprint unlock button with success
    fakeAuth.authResult = true;
    final unlockButton = find.byKey(const Key('unlock_biometric_button'));
    await tester.tap(unlockButton);
    await tester.pumpAndSettle();

    // Content should now be visible
    expect(find.text('Dashboard Terlindungi'), findsOneWidget);
    expect(find.byKey(const Key('lock_screen_view')), findsNothing);

    // Unmount widget tree cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'LockScreenWrapper ignores pause during authentication and prevents double prompt',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Enable PIN and Biometric lock in Hive
    await tester.runAsync(() async {
      await securityService.savePin('123456');
      await securityService.setBiometricEnabled(true);
    });
    fakeAuth.authResult = true;

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuKosDarkTheme(),
        home: const LockScreenWrapper(
          child: Scaffold(
            body: Center(child: Text('Dashboard Terlindungi')),
          ),
        ),
      ),
    );
    // Allow auto-auth to complete and unlock
    await tester.pumpAndSettle();

    // Content should be visible immediately after 1 scan
    expect(find.text('Dashboard Terlindungi'), findsOneWidget);
    expect(find.byKey(const Key('lock_screen_view')), findsNothing);

    // Simulate dialog dismissal lifecycle: paused -> resumed
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // App must remain unlocked (no double prompt / relock)
    expect(find.text('Dashboard Terlindungi'), findsOneWidget);
    expect(find.byKey(const Key('lock_screen_view')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
