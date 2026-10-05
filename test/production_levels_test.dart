import 'package:cross_slow/campaign/campaign_chapter.dart';
import 'package:cross_slow/campaign/chapter_transition_screen.dart';
import 'package:cross_slow/campaign/chapter_scene_reveal_screen.dart';
import 'package:cross_slow/app/cross_slow_app.dart';
import 'package:cross_slow/features/game/data/level_repository.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/home/home_screen.dart';
import 'package:cross_slow/features/splash/splash_screen.dart';
import 'package:cross_slow/progress/achievements.dart';
import 'package:cross_slow/progress/campaign_progress.dart';
import 'package:cross_slow/progress/progress_repository.dart';
import 'package:cross_slow/progress/theme_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'production campaign has 150 sequential levels and unique sets',
    () async {
      final levels = await LevelRepository().load();
      expect(levels, hasLength(150));
      expect(
        levels.map((level) => level.id),
        orderedEquals(List.generate(150, (i) => i + 1)),
      );
      expect(
        levels.map((level) => ([...level.letters]..sort()).join()).toSet(),
        hasLength(150),
      );
    },
  );

  test('chapters and one-time transitions use their configured boundaries', () {
    expect(CampaignChapters.forLevel(37).name, 'Озеро');
    expect(CampaignChapters.forLevel(37).positionOf(37), 17);
    expect(CampaignChapters.forLevel(37).totalLevels, 30);
    for (final boundary in [20, 50, 80, 110]) {
      final chapter = CampaignChapters.afterLevel(boundary);
      expect(chapter!.firstLevel, boundary + 1);
      expect(CampaignChapters.forLevel(boundary + 1), chapter);
    }
    expect(CampaignChapters.afterLevel(150), isNull);
    expect(() => CampaignChapters.forLevel(151), throwsRangeError);
  });

  test('chapter transition is queued once after each boundary', () async {
    final levels = await LevelRepository().load();
    for (final boundary in [20, 50, 80, 110]) {
      final state = CampaignProgress(currentLevel: boundary);
      expect(state.complete(levels[boundary - 1]), isTrue);
      expect(state.currentLevel, boundary + 1);
      expect(
        state.pendingChapterId,
        CampaignChapters.forLevel(boundary + 1).id,
      );
      expect(state.complete(levels[boundary - 1]), isFalse);
      state.acknowledgeChapter();
      expect(state.pendingChapterId, isNull);
    }
  });

  test('completion, counters and achievements cannot repeat', () async {
    final levels = await LevelRepository().load();
    final first = levels.first;
    final state = CampaignProgress(crystals: CampaignProgress.hintCost);
    expect(state.recordWord(first, first.words.first.text), isTrue);
    expect(state.recordWord(first, first.words.first.text), isFalse);
    expect(state.wordsFound, 1);
    expect(state.recordHint(1), isTrue);
    expect(state.hintsUsed, 1);
    expect(state.crystals, 0);
    expect(state.complete(first), isTrue);
    expect(state.complete(first), isFalse);
    expect(state.completedLevels, 1);
    expect(state.levelsWithoutHints, 0);
    expect(state.crystalsEarned, 3);
    expect(state.crystals, 3);
    expect(
      AchievementRules.unlockNew(state, levels, DateTime.utc(2026)),
      contains(AchievementRules.all.first),
    );
    expect(
      AchievementRules.unlockNew(state, levels, DateTime.utc(2026)),
      isEmpty,
    );
  });

  test('hint costs ten crystals and cannot overdraw balance', () {
    final state = CampaignProgress(crystals: 19);
    expect(state.recordHint(1), isTrue);
    expect(state.crystals, 9);
    expect(state.hintsUsed, 1);
    expect(state.recordHint(1), isFalse);
    expect(state.crystals, 9);
    expect(state.hintsUsed, 1);

    final restored = CampaignProgress.fromJson(state.toJson());
    expect(restored.crystals, 9);
    expect(restored.hintsUsed, 1);
  });

  test('level 150 ends without level 151', () async {
    final levels = await LevelRepository().load();
    final state = CampaignProgress(
      currentLevel: 150,
      completed: {for (var id = 1; id < 150; id++) id},
    );
    expect(state.complete(levels.last), isTrue);
    expect(state.campaignCompleted, isTrue);
    expect(state.currentLevel, 150);
    expect(state.pendingChapterId, isNull);
    expect(
      AchievementRules.unlockNew(
        state,
        levels,
        DateTime.utc(2026),
      ).map((achievement) => achievement.id),
      contains('cross_slow'),
    );
  });

  test(
    'hint-free levels count once and unlock the tenth-level achievement',
    () async {
      final levels = await LevelRepository().load();
      final state = CampaignProgress();
      for (final level in levels.take(10)) {
        expect(state.complete(level), isTrue);
      }
      expect(state.levelsWithoutHints, 10);
      expect(state.currentStreak, 10);
      expect(state.bestStreak, 10);
      final unlocked = AchievementRules.unlockNew(
        state,
        levels,
        DateTime.utc(2026),
      );
      expect(unlocked.map((a) => a.id), contains('no_hints_10'));
      expect(
        AchievementRules.unlockNew(state, levels, DateTime.utc(2026)),
        isEmpty,
      );
    },
  );

  test(
    'state and achievements restore; legacy test progress resets once',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = SharedPreferencesAsync();
      await preferences.setInt('current_level', 13);
      await preferences.setStringList('completed_levels', ['1', '2', '3']);
      await preferences.setInt('crystal_balance', 39);
      await preferences.setBool('light_theme', true);
      final repository = ProgressRepository();
      final state = await repository.load();
      expect(state.currentLevel, 1);
      expect(state.completed, isEmpty);
      expect(state.crystals, 0);
      expect(await ThemeRepository().load(), ThemeMode.light);
      expect(await preferences.getInt('current_level'), isNull);
      expect(await preferences.getStringList('completed_levels'), isNull);
      expect(await preferences.getInt('crystal_balance'), isNull);
      state.unlockedAt['first_step'] = DateTime.utc(2026, 10, 4);
      state.currentLevel = 21;
      state.pendingChapterId = 2;
      await repository.save(state);
      final restored = await ProgressRepository().load();
      expect(restored.currentLevel, 21);
      expect(restored.pendingChapterId, 2);
      expect(restored.unlockedAt['first_step'], DateTime.utc(2026, 10, 4));
      restored.acknowledgeChapter();
      await repository.save(restored);
      expect((await repository.load()).pendingChapterId, isNull);
    },
  );

  for (final (levelId, chapterId, chapterName, sceneTitle, sceneId)
      in <(int, int, String, String, String)>[
        (21, 2, 'ОЗЕРО', 'БЕРЕГ ОЗЕРА', 'lake_01'),
        (51, 3, 'ГОРЫ', 'НАЧАЛО ПОДЪЁМА', 'mountains_01'),
        (81, 4, 'ЗАМОК', 'У ВОРОТ', 'castle_01'),
        (111, 5, 'СЕВЕР', 'СЕВЕРНАЯ ДОЛИНА', 'north_01'),
      ]) {
    testWidgets('chapter $chapterId opens its scene before level $levelId', (
      tester,
    ) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      await ProgressRepository().save(
        CampaignProgress(
          currentLevel: levelId,
          completed: {for (var id = 1; id < levelId; id++) id},
          pendingChapterId: chapterId,
        ),
      );
      await tester.pumpWidget(const CrossSlowApp());
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('doc/load.png'),
          tester.element(find.byType(SplashScreen)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(ChapterTransitionScreen), findsOneWidget);
      expect(find.text(chapterName), findsOneWidget);
      await tester.tap(find.text('ПРОДОЛЖИТЬ'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ChapterSceneRevealScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(sceneTitle), findsOneWidget);
      await tester.tap(find.text('ПРОДОЛЖИТЬ'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect((await ProgressRepository().load()).seenScenes, contains(sceneId));
      await tester.tap(find.text('ПРОДОЛЖИТЬ'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<GameScreen>(find.byType(GameScreen)).level.id,
        levelId,
      );
      expect((await ProgressRepository().load()).pendingChapterId, isNull);
    });
  }

  testWidgets('level 143 opens the final scene once', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await ProgressRepository().save(
      CampaignProgress(
        currentLevel: 143,
        completed: {for (var id = 1; id <= 142; id++) id},
      ),
    );
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
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('КРАЙ СВЕТА'), findsOneWidget);
    await tester.tap(find.text('ПРОДОЛЖИТЬ'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      (await ProgressRepository().load()).seenScenes,
      contains('north_05'),
    );
  });

  testWidgets('completed campaign shows final once and starts Endless', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await ProgressRepository().save(
      CampaignProgress(
        currentLevel: 150,
        completed: {for (var id = 1; id <= 150; id++) id},
      ),
    );
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
    expect(find.text('ПУТЕШЕСТВИЕ ЗАВЕРШЕНО'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.tap(find.text('ПРОДОЛЖИТЬ ИГРАТЬ'));
    await tester.pump();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('КРАЙ СВЕТА'), findsOneWidget);
    expect(find.text('150 / 150'), findsOneWidget);
    expect(find.text('Бесконечная игра · 0'), findsOneWidget);
    await tester.tap(find.text('ИГРАТЬ'));
    await tester.pump();
    final game = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(game.endlessRound, 1);
    expect(game.level.id, inInclusiveRange(50, 150));
    expect(game.sceneOverride?.id, 'north_05');
    expect(find.text('БЕСКОНЕЧНАЯ ИГРА'), findsOneWidget);
    expect(find.text('УРОВЕНЬ ${game.level.id}'), findsNothing);
    for (final word in game.level.words) {
      game.onWordFound?.call(word.text);
    }
    game.onComplete();
    await tester.pump();
    expect((await ProgressRepository().load()).endlessRoundsCompleted, 1);
    game.onNext();
    await tester.pump(const Duration(milliseconds: 100));
    final second = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(second.endlessRound, 2);
    expect(second.level.id, isNot(game.level.id));
    expect(second.sceneOverride?.id, 'north_05');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Бесконечная игра · 1'), findsOneWidget);
    final stored = await ProgressRepository().load();
    expect(stored.completedLevels, 150);
    expect(stored.currentLevel, 150);
    expect(stored.campaignFinalSeen, isTrue);
    expect(stored.activeEndlessSourceLevelId, second.level.id);
    await tester.pumpWidget(const SizedBox.shrink());
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
    expect(find.byType(ChapterSceneRevealScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('150 / 150'), findsOneWidget);
    expect(find.text('Бесконечная игра · 1'), findsOneWidget);
    await tester.tap(find.text('ИГРАТЬ'));
    await tester.pump();
    final resumed = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(resumed.endlessRound, 2);
    expect(resumed.level.id, second.level.id);
  });
}
