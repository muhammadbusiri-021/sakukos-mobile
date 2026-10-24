import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sakukos/services/category_service.dart';

void main() {
  group('CategoryService Tests', () {
    late Directory tempDir;
    late CategoryService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sakukos_cat_test_');
      Hive.init(tempDir.path);
      service = CategoryService();
      await service.init();
      await service.box.clear();
      // Re-init to repopulate defaults after clear
      await service.init();
    });

    tearDown(() async {
      await service.box.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('initializes with default categories without Lainnya', () {
      final categories = service.getCategories();
      expect(categories.length, 5);
      expect(categories.length, CategoryService.defaultCategories.length);
      expect(categories, contains('Makan'));
      expect(categories, contains('Kosan'));
      expect(categories, contains('Nongkrong'));
      expect(categories, contains('Transport'));
      expect(categories, contains('Belajar'));
      expect(categories, isNot(contains('Lainnya')));
    });

    test('addCategory adds a new category', () async {
      await service.addCategory('Paket Data');
      final categories = service.getCategories();
      expect(categories, contains('Paket Data'));
      expect(categories.length, CategoryService.defaultCategories.length + 1);
    });

    test('addCategory does not add duplicate, empty, or Lainnya category', () async {
      final initialCount = service.getCategories().length;
      await service.addCategory('makan'); // case-insensitive duplicate
      await service.addCategory('   '); // whitespace only
      await service.addCategory('Lainnya'); // disallowed redundant category
      await service.addCategory('lainnya');
      final updated = service.getCategories();
      expect(updated.length, initialCount);
      expect(updated, isNot(contains('Lainnya')));
    });

    test('addCategory rejects reserved keywords (semua, all) with system error message', () async {
      final initialCount = service.getCategories().length;

      final errorSemua = await service.addCategory('Semua');
      expect(
        errorSemua,
        "Nama 'Semua' adalah filter sistem dan tidak dapat digunakan.",
      );

      final errorSemuaLower = await service.addCategory('semua');
      expect(
        errorSemuaLower,
        "Nama 'Semua' adalah filter sistem dan tidak dapat digunakan.",
      );

      final errorAll = await service.addCategory('all');
      expect(
        errorAll,
        "Nama 'Semua' adalah filter sistem dan tidak dapat digunakan.",
      );

      final errorLainnya = await service.addCategory('Lainnya');
      expect(
        errorLainnya,
        "Nama 'Semua' adalah filter sistem dan tidak dapat digunakan.",
      );

      expect(service.getCategories().length, initialCount);
    });

    test('automatically removes legacy Lainnya, Semua, and All and auto-restores defaults if emptied', () async {
      // Simulate corrupted/legacy database with 'semua' and 'all'
      await service.box.put(CategoryService.categoriesKey, [
        'semua',
        'All',
        'Lainnya',
      ]);
      // After cleaning, since no valid categories remain, it must auto-restore the 5 defaults
      final restored = service.getCategories();
      expect(restored.length, 5);
      expect(restored, contains('Makan'));
      expect(restored, contains('Kosan'));
      expect(restored, contains('Nongkrong'));
      expect(restored, contains('Transport'));
      expect(restored, contains('Belajar'));
      expect(restored, isNot(contains('semua')));
      expect(restored, isNot(contains('All')));

      // Re-running init cleans up the box persistence
      await service.init();
      final storedInBox = service.box.get(CategoryService.categoriesKey) as List;
      expect(storedInBox.length, 5);
      expect(storedInBox, isNot(contains('semua')));
      expect(storedInBox, isNot(contains('All')));
    });

    test('isDefaultCategory identifies default vs custom categories', () {
      expect(service.isDefaultCategory('Makan'), isTrue);
      expect(service.isDefaultCategory('makan'), isTrue);
      expect(service.isDefaultCategory('Kosan'), isTrue);
      expect(service.isDefaultCategory('Nongkrong'), isTrue);
      expect(service.isDefaultCategory('Transport'), isTrue);
      expect(service.isDefaultCategory('Belajar'), isTrue);

      expect(service.isDefaultCategory('Paket Data'), isFalse);
      expect(service.isDefaultCategory('Lainnya'), isFalse);
      expect(service.isDefaultCategory(''), isFalse);
    });

    test('deleteCategory deletes any category as long as at least 1 remains', () async {
      // Add custom category
      await service.addCategory('Skincare');
      expect(service.getCategories(), contains('Skincare'));

      // Can delete custom category
      final deletedCustom = await service.deleteCategory('Skincare');
      expect(deletedCustom, isTrue);
      expect(service.getCategories(), isNot(contains('Skincare')));

      // Can delete default category as well
      final deletedMakan = await service.deleteCategory('Makan');
      expect(deletedMakan, isTrue);
      expect(service.getCategories(), isNot(contains('Makan')));

      // Delete down until only 1 category remains
      // Remaining: Kosan, Nongkrong, Transport, Belajar (4)
      await service.deleteCategory('Kosan');
      await service.deleteCategory('Nongkrong');
      await service.deleteCategory('Transport');
      // Only Belajar left (1 category)
      expect(service.getCategories().length, 1);
      expect(service.getCategories(), contains('Belajar'));

      // Attempt to delete the last remaining category MUST be rejected
      final deletedLast = await service.deleteCategory('Belajar');
      expect(deletedLast, isFalse);
      expect(service.getCategories().length, 1);
      expect(service.getCategories(), contains('Belajar'));

      // Deleting empty or non-existent does nothing
      final countBefore = service.getCategories().length;
      await service.deleteCategory('');
      await service.deleteCategory('NonExistent');
      expect(service.getCategories().length, countBefore);
    });
  });
}
