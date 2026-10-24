import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sakukos/models/debt_item.dart';
import 'package:sakukos/services/debt_service.dart';

void main() {
  group('DebtItem Model Tests', () {
    test('toMap and fromMap serialize and deserialize accurately', () {
      final now = DateTime(2026, 10, 22, 10, 30);
      final item = DebtItem(
        id: 'debt_1',
        friendName: 'Budi',
        description: 'Patungan Mie Ayam',
        amount: 25000.0,
        date: now,
        isSettled: false,
      );

      final map = item.toMap();
      final fromMap = DebtItem.fromMap(map);

      expect(fromMap.id, item.id);
      expect(fromMap.friendName, item.friendName);
      expect(fromMap.description, item.description);
      expect(fromMap.amount, item.amount);
      expect(fromMap.date.toIso8601String(), item.date.toIso8601String());
      expect(fromMap.isSettled, isFalse);
    });

    test('copyWith updates specified attributes only', () {
      final item = DebtItem(
        id: 'debt_2',
        friendName: 'Rian',
        description: 'Bensin Beat',
        amount: 20000.0,
        date: DateTime.now(),
        isSettled: false,
      );

      final updated = item.copyWith(isSettled: true, amount: 25000.0);
      expect(updated.id, item.id);
      expect(updated.friendName, 'Rian');
      expect(updated.description, 'Bensin Beat');
      expect(updated.amount, 25000.0);
      expect(updated.isSettled, isTrue);
    });
  });

  group('DebtService Database Tests', () {
    late Directory tempDir;
    late DebtService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sakukos_debt_test_');
      Hive.init(tempDir.path);
      service = DebtService();
      await service.init();
      await service.box.clear();
    });

    tearDown(() async {
      await service.box.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('addDebt, getActiveDebts, and getSettledDebts functionality', () async {
      final item1 = DebtItem(
        id: '1',
        friendName: 'Dimas',
        description: 'Kopi Kenangan',
        amount: 22000.0,
        date: DateTime(2026, 10, 20),
        isSettled: false,
      );
      final item2 = DebtItem(
        id: '2',
        friendName: 'Farhan',
        description: 'Nasi Goreng',
        amount: 18000.0,
        date: DateTime(2026, 10, 21),
        isSettled: true,
      );

      await service.addDebt(item1);
      await service.addDebt(item2);

      final active = service.getActiveDebts();
      final settled = service.getSettledDebts();

      expect(active.length, 1);
      expect(active.first.friendName, 'Dimas');
      expect(settled.length, 1);
      expect(settled.first.friendName, 'Farhan');
    });

    test('toggleSettleStatus switches debt status and updates unsettled total',
        () async {
      final item = DebtItem(
        id: 'debt_toggle',
        friendName: 'Budi',
        description: 'Tiket Bioskop',
        amount: 45000.0,
        date: DateTime.now(),
        isSettled: false,
      );

      await service.addDebt(item);
      expect(service.getTotalUnsettledAmount(), 45000.0);
      expect(service.getActiveDebts().length, 1);
      expect(service.getSettledDebts().isEmpty, isTrue);

      // Tandai lunas
      await service.toggleSettleStatus('debt_toggle');
      expect(service.getTotalUnsettledAmount(), 0.0);
      expect(service.getActiveDebts().isEmpty, isTrue);
      expect(service.getSettledDebts().length, 1);

      // Kembalikan ke belum lunas
      await service.toggleSettleStatus('debt_toggle');
      expect(service.getTotalUnsettledAmount(), 45000.0);
      expect(service.getActiveDebts().length, 1);
      expect(service.getSettledDebts().isEmpty, isTrue);
    });

    test('deleteDebt removes item from database', () async {
      final item = DebtItem(
        id: 'debt_delete',
        friendName: 'Reno',
        description: 'Gorengan',
        amount: 10000.0,
        date: DateTime.now(),
      );

      await service.addDebt(item);
      expect(service.getActiveDebts().length, 1);

      await service.deleteDebt('debt_delete');
      expect(service.getActiveDebts().isEmpty, isTrue);
      expect(service.getTotalUnsettledAmount(), 0.0);
    });
  });
}
