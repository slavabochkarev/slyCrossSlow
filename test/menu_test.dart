import 'package:cross_slow/core/theme/game_theme.dart';
import 'package:cross_slow/features/menu/menu_screen.dart';
import 'package:cross_slow/progress/theme_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme choice is saved and restored', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final repository = ThemeRepository();
    expect(await repository.load(), ThemeMode.dark);
    await repository.save(ThemeMode.light);
    expect(await ThemeRepository().load(), ThemeMode.light);
  });

  for (final size in [const Size(390, 700), const Size(1100, 700)]) {
    testWidgets(
      'menu fits and opens its sections at ${size.width}x${size.height}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        ThemeMode? chosen;
        await tester.pumpWidget(
          MaterialApp(
            theme: GameTheme.dark,
            home: MenuScreen(
              themeMode: ThemeMode.dark,
              onThemeChanged: (mode) => chosen = mode,
              completed: 1,
              totalLevels: 3,
              foundWords: 2,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Светлая'));
        await tester.pump();
        expect(chosen, ThemeMode.light);
        await tester.tap(find.text('Статистика'));
        await tester.pumpAndSettle();
        expect(find.text('1 / 3'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('ИНФО'));
        await tester.pumpAndSettle();
        expect(find.text('Как играть'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
