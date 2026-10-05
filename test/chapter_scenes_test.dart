import 'package:cross_slow/app/cross_slow_app.dart';
import 'package:cross_slow/campaign/chapter_scene.dart';
import 'package:cross_slow/campaign/chapter_scene_reveal_screen.dart';
import 'package:cross_slow/core/theme/game_theme.dart';
import 'package:cross_slow/features/home/home_screen.dart';
import 'package:cross_slow/features/splash/splash_screen.dart';
import 'package:cross_slow/progress/campaign_progress.dart';
import 'package:cross_slow/progress/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 150 levels map to exactly one of 20 scenes', () {
    expect(ChapterScenes.all, hasLength(20));
    expect(ChapterScenes.all.map((scene) => scene.id).toSet(), hasLength(20));
    for (var level = 1; level <= 150; level++) {
      expect(ChapterScenes.forLevel(level), isNotNull, reason: 'Level $level');
      expect(
        ChapterScenes.all.where((scene) => scene.contains(level)),
        hasLength(1),
        reason: 'Level $level',
      );
    }
    expect(ChapterScenes.forLevel(0), isNull);
    expect(ChapterScenes.forLevel(151), isNull);
  });

  test('scene mapping includes every boundary and opening', () {
    final expected = {
      20: 'forest_03',
      1: 'forest_01',
      7: 'forest_01',
      8: 'forest_02',
      14: 'forest_02',
      15: 'forest_03',
      21: 'lake_01',
      27: 'lake_01',
      28: 'lake_02',
      34: 'lake_02',
      35: 'lake_03',
      42: 'lake_03',
      43: 'lake_04',
      50: 'lake_04',
      51: 'mountains_01',
      57: 'mountains_01',
      58: 'mountains_02',
      64: 'mountains_02',
      65: 'mountains_03',
      72: 'mountains_03',
      73: 'mountains_04',
      80: 'mountains_04',
      81: 'castle_01',
      87: 'castle_01',
      88: 'castle_02',
      94: 'castle_02',
      95: 'castle_03',
      102: 'castle_03',
      103: 'castle_04',
      110: 'castle_04',
      111: 'north_01',
      118: 'north_01',
      119: 'north_02',
      126: 'north_02',
      127: 'north_03',
      134: 'north_03',
      135: 'north_04',
      142: 'north_04',
      143: 'north_05',
      150: 'north_05',
    };
    for (final entry in expected.entries) {
      expect(ChapterScenes.forLevel(entry.key)?.id, entry.value);
    }
    expect(ChapterScenes.openingForLevel(1)?.id, 'forest_01');
    expect(ChapterScenes.openingForLevel(8)?.id, 'forest_02');
    expect(ChapterScenes.openingForLevel(15)?.id, 'forest_03');
    expect(ChapterScenes.openingForLevel(21)?.id, 'lake_01');
    expect(ChapterScenes.openingForLevel(28)?.id, 'lake_02');
    expect(ChapterScenes.openingForLevel(35)?.id, 'lake_03');
    expect(ChapterScenes.openingForLevel(43)?.id, 'lake_04');
    expect(ChapterScenes.openingForLevel(51)?.id, 'mountains_01');
    expect(ChapterScenes.openingForLevel(58)?.id, 'mountains_02');
    expect(ChapterScenes.openingForLevel(65)?.id, 'mountains_03');
    expect(ChapterScenes.openingForLevel(73)?.id, 'mountains_04');
    expect(ChapterScenes.openingForLevel(81)?.id, 'castle_01');
    expect(ChapterScenes.openingForLevel(88)?.id, 'castle_02');
    expect(ChapterScenes.openingForLevel(95)?.id, 'castle_03');
    expect(ChapterScenes.openingForLevel(103)?.id, 'castle_04');
    expect(ChapterScenes.openingForLevel(111)?.id, 'north_01');
    expect(ChapterScenes.openingForLevel(119)?.id, 'north_02');
    expect(ChapterScenes.openingForLevel(127)?.id, 'north_03');
    expect(ChapterScenes.openingForLevel(135)?.id, 'north_04');
    expect(ChapterScenes.openingForLevel(143)?.id, 'north_05');
    expect(ChapterScenes.openingForLevel(7), isNull);
    expect(ChapterScenes.openingForLevel(27), isNull);
    expect(ChapterScenes.openingForLevel(57), isNull);
    expect(
      ChapterScenes.unseenOpeningForLevel(8, {'forest_01'})?.id,
      'forest_02',
    );
    expect(
      ChapterScenes.unseenOpeningForLevel(15, {'forest_01', 'forest_02'})?.id,
      'forest_03',
    );
    expect(ChapterScenes.unseenOpeningForLevel(8, {'forest_02'}), isNull);
    expect(
      ChapterScenes.unseenOpeningForLevel(21, {
        'forest_01',
        'forest_02',
        'forest_03',
      })?.id,
      'lake_01',
    );
    expect(ChapterScenes.unseenOpeningForLevel(21, {'lake_01'}), isNull);
    expect(
      ChapterScenes.unseenOpeningForLevel(51, {'lake_04'})?.id,
      'mountains_01',
    );
    expect(ChapterScenes.unseenOpeningForLevel(51, {'mountains_01'}), isNull);
    expect(
      ChapterScenes.unseenOpeningForLevel(81, {'mountains_04'})?.id,
      'castle_01',
    );
    expect(
      ChapterScenes.unseenOpeningForLevel(111, {'castle_04'})?.id,
      'north_01',
    );
    expect(
      ChapterScenes.unseenOpeningForLevel(143, {'north_04'})?.id,
      'north_05',
    );
    expect(ChapterScenes.unseenOpeningForLevel(143, {'north_05'}), isNull);
  });

  for (final size in <Size>[
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
    const Size(1024, 768),
    const Size(1200, 800),
  ]) {
    for (final level in [
      1,
      8,
      15,
      21,
      28,
      35,
      43,
      51,
      58,
      65,
      73,
      81,
      88,
      95,
      103,
      111,
      119,
      127,
      135,
      143,
    ]) {
      testWidgets('scene Home level $level fits ${size.width}×${size.height}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: GameTheme.dark,
            home: HomeScreen(
              level: level,
              totalLevels: 150,
              completed: level - 1,
              onContinue: () {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        final scene = ChapterScenes.forLevel(level)!;
        final image = tester.widget<Image>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName == scene.backgroundAsset,
          ),
        );
        expect(image.fit, BoxFit.cover);
        expect(image.alignment, scene.focalAlignment);
        expect(find.text('УРОВЕНЬ $level'), findsOneWidget);
        expect(find.text('ПРОДОЛЖИТЬ'), findsOneWidget);
      });
    }
  }

  testWidgets('scene opening is shown once and saved in campaign progress', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await ProgressRepository().save(CampaignProgress(currentLevel: 8));
    await tester.pumpWidget(const CrossSlowApp());
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('doc/load.png'),
        tester.element(find.byType(SplashScreen)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.byType(ChapterSceneRevealScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('ПРОДОЛЖИТЬ'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      (await ProgressRepository().load()).seenScenes,
      contains('forest_02'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const CrossSlowApp());
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('doc/load.png'),
        tester.element(find.byType(SplashScreen)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ChapterSceneRevealScreen), findsNothing);
  });
}
