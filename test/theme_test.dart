import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sakukos/core/theme.dart';

void main() {
  group('ThemeNotifier', () {
    test('default mode is dark', () {
      final notifier = ThemeNotifier();
      expect(notifier.value, ThemeMode.dark);
      expect(notifier.isDarkMode, isTrue);
    });

    test('toggleTheme alternates between dark and light', () {
      final notifier = ThemeNotifier();
      notifier.toggleTheme();
      expect(notifier.value, ThemeMode.light);
      expect(notifier.isDarkMode, isFalse);

      notifier.toggleTheme();
      expect(notifier.value, ThemeMode.dark);
      expect(notifier.isDarkMode, isTrue);
    });
  });

  group('ThemeNotifier Hive Persistence', () {
    late Directory tempDir;
    late Box settingsBox;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sakukos_theme_test_');
      Hive.init(tempDir.path);
      settingsBox = await Hive.openBox(ThemeNotifier.boxName);
      await settingsBox.clear();
    });

    tearDown(() async {
      await settingsBox.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('init loads default dark mode when key is absent', () async {
      final notifier = ThemeNotifier();
      await notifier.init();
      expect(notifier.value, ThemeMode.dark);
      expect(notifier.isDarkMode, isTrue);
    });

    test('init restores light mode when is_dark_mode is false', () async {
      await settingsBox.put(ThemeNotifier.keyIsDarkMode, false);
      final notifier = ThemeNotifier();
      await notifier.init();
      expect(notifier.value, ThemeMode.light);
      expect(notifier.isDarkMode, isFalse);
    });

    test('toggleTheme updates and persists to Hive settings_box', () async {
      final notifier = ThemeNotifier(ThemeMode.dark);
      notifier.toggleTheme();
      expect(notifier.value, ThemeMode.light);
      expect(settingsBox.get(ThemeNotifier.keyIsDarkMode), isFalse);

      notifier.toggleTheme();
      expect(notifier.value, ThemeMode.dark);
      expect(settingsBox.get(ThemeNotifier.keyIsDarkMode), isTrue);
    });

    test('setDarkMode persists explicit preference to Hive', () async {
      final notifier = ThemeNotifier(ThemeMode.dark);
      notifier.setDarkMode(false);
      expect(notifier.value, ThemeMode.light);
      expect(settingsBox.get(ThemeNotifier.keyIsDarkMode), isFalse);

      notifier.setDarkMode(true);
      expect(notifier.value, ThemeMode.dark);
      expect(settingsBox.get(ThemeNotifier.keyIsDarkMode), isTrue);
    });

    test(
        'simulated app restart preserves chosen theme preference 100%',
        () async {
      // 1. User switches to light mode
      final initialNotifier = ThemeNotifier(ThemeMode.dark);
      initialNotifier.toggleTheme();
      expect(initialNotifier.value, ThemeMode.light);
      expect(settingsBox.get(ThemeNotifier.keyIsDarkMode), isFalse);

      // 2. App killed / new session initialized
      final restartedNotifier = ThemeNotifier();
      await restartedNotifier.init();
      expect(restartedNotifier.value, ThemeMode.light);
      expect(restartedNotifier.isDarkMode, isFalse);
    });
  });

  group('SakuKos Theme Factories', () {
    testWidgets('sakuKosDarkTheme has dark brightness and custom extensions',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: sakuKosDarkTheme(),
          home: const Scaffold(),
        ),
      );
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, SakuKosDarkColors.scaffold);
      expect(theme.extension<SakuKosPalette>(), isNotNull);
    });

    testWidgets('sakuKosLightTheme has light brightness and custom extensions',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: sakuKosLightTheme(),
          home: const Scaffold(),
        ),
      );
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, SakuKosLightColors.scaffold);
      expect(theme.extension<SakuKosPalette>(), isNotNull);
    });
  });
}
