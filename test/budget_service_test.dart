import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sakukos/services/budget_service.dart';

void main() {
  late Directory tempDir;
  late BudgetService budgetService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sakukos_budget_test_');
    Hive.init(tempDir.path);
    budgetService = BudgetService();
    await budgetService.init();
    await budgetService.box.clear();
  });

  tearDown(() async {
    await budgetService.box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BudgetService Tests', () {
    test('default daily budget is 50000.0', () {
      expect(budgetService.getDailyBudget(), 50000.0);
    });

    test('setDailyBudget updates stored daily budget', () async {
      await budgetService.setDailyBudget(45000.0);
      expect(budgetService.getDailyBudget(), 45000.0);

      await budgetService.setDailyBudget(30000.0);
      expect(budgetService.getDailyBudget(), 30000.0);
    });

    test('setMonthlyBudget divides monthly amount by days in current month',
        () async {
      final now = DateTime.now();
      final daysInMonth = max(1, DateTime(now.year, now.month + 1, 0).day);

      const monthlyAmount = 1500000.0;
      await budgetService.setMonthlyBudget(monthlyAmount);

      final expectedDaily = monthlyAmount / daysInMonth;
      expect(budgetService.getDailyBudget(), expectedDaily);
    });

    test('listenable notifies when budget is updated', () async {
      int notifyCount = 0;
      final listenable = budgetService.listenable;
      void listener() => notifyCount++;

      listenable.addListener(listener);
      await budgetService.setDailyBudget(60000.0);

      expect(notifyCount, greaterThan(0));
      listenable.removeListener(listener);
    });
  });
}
