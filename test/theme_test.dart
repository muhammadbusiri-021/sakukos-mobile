import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
