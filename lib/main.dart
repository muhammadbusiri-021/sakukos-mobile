import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme.dart';
import 'screens/lock_screen_wrapper.dart';
import 'screens/main_screen.dart';
import 'services/biometric_service.dart';
import 'services/budget_service.dart';
import 'services/category_service.dart';
import 'services/debt_service.dart';
import 'services/security_service.dart';
import 'services/transaction_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await TransactionService().init();
  await BudgetService().init();
  await DebtService().init();
  await CategoryService().init();
  await SecurityService().init();
  await BiometricService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'SakuKos',
          debugShowCheckedModeBanner: false,
          theme: sakuKosLightTheme(),
          darkTheme: sakuKosDarkTheme(),
          themeMode: currentMode,
          home: const LockScreenWrapper(child: MainScreen()),
        );
      },
    );
  }
}
