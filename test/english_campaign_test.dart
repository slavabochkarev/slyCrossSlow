import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cross_slow/app/cross_slow_app.dart';
import 'package:cross_slow/campaign/chapter_scene_reveal_screen.dart';
import 'package:cross_slow/features/game/controller/game_controller.dart';
import 'package:cross_slow/features/game/data/game_dictionary.dart';
import 'package:cross_slow/features/game/data/level_repository.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/game/models/level.dart';
import 'package:cross_slow/features/home/home_screen.dart';
import 'package:cross_slow/features/menu/menu_screen.dart';
import 'package:cross_slow/features/splash/splash_screen.dart';
import 'package:cross_slow/game_language.dart';
import 'package:cross_slow/progress/campaign_progress.dart';
import 'package:cross_slow/progress/achievements.dart';
import 'package:cross_slow/progress/game_profiles.dart';
import 'package:cross_slow/progress/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'all 150 English production levels load and use the English game engine',
    () async {
      final levels = await LevelRepository().load(GameLanguage.en);
      final game = await GameDictionary.loadGameWords(GameLanguage.en);
      expect(levels.length, 150);
      expect(await LevelRepository().hasCampaign(GameLanguage.en), isTrue);
      final signatures = <String>{};
      for (var index = 0; index < levels.length; index++) {
        final level = levels[index];
        expect(level.id, index + 1);
        expect(signatures.add(([...level.letters]..sort()).join()), isTrue);
        final controller = GameController(level, language: GameLanguage.en);
        final cells = <String, String>{};
        for (final word in level.words) {
          expect(game, contains(word.text));
          expect(word.text, matches(RegExp(r'^[A-Z]{3,7}$')));
          final remaining = [...level.letters];
          for (final letter in word.text.split('')) {
            expect(remaining.remove(letter), isTrue);
          }
          for (var i = 0; i < word.text.length; i++) {
            final row = word.row + (word.down ? i : 0);
            final col = word.col + (word.down ? 0 : i);
            expect(row, inInclusiveRange(0, level.rows - 1));
            expect(col, inInclusiveRange(0, level.cols - 1));
            final key = '$row:$col';
            if (cells.containsKey(key)) expect(cells[key], word.text[i]);
            cells[key] = word.text[i];
          }
          expect(controller.submit(word.text), WordResult.correct);
        }
        expect(controller.completed, isTrue);
        controller.dispose();
      }
      expect(
        levels.skip(110).every((level) => level.words.length >= 13),
        isTrue,
      );
      expect(levels.any((level) => level.words.length >= 16), isTrue);
    },
  );

  test(
    'the first twenty production puzzles are the approved puzzles',
    () async {
      final source = jsonDecode(
        File('tools/level_generator/english_preview/levels_en_preview.json')
            .readAsStringSync(),
      ) as List;
      final production = await LevelRepository().load(GameLanguage.en);
      for (var index = 0; index < 20; index++) {
        final approved = Level.fromJson(source[index] as Map<String, dynamic>);
        final level = production[index];
        expect(level.letters, approved.letters);
        expect(
          level.words.map((w) => [w.text, w.row, w.col, w.down]).toList(),
          approved.words.map((w) => [w.text, w.row, w.col, w.down]).toList(),
        );
        expect([level.rows, level.cols], [approved.rows, approved.cols]);
      }
    },
  );

  test(
    'both languages award once and spend from one persisted wallet',
    () async {
      final ru = await LevelRepository().load();
      final en = await LevelRepository().load(GameLanguage.en);
      final profiles = GameProfiles(ru: CampaignProgress(crystals: 20));
      expect(profiles.ru.complete(ru.first), isTrue);
      expect(profiles.ru.crystals, 23);
      expect(profiles.ru.complete(ru.first), isFalse);
      profiles.select(GameLanguage.en);
      expect(profiles.en.crystals, 23);
      expect(profiles.en.recordHint(1), isTrue);
      expect(profiles.en.crystals, 13);
      expect(profiles.en.complete(en.first), isTrue);
      expect(profiles.en.crystals, 16);
      expect(profiles.en.complete(en.first), isFalse);
      profiles.select(GameLanguage.ru);
      expect(profiles.ru.recordHint(2), isTrue);
      await ProgressRepository().saveProfiles(profiles);
      final restored = await ProgressRepository().loadProfiles();
      expect(restored.crystals, 6);
      expect(restored.ru.crystals, 6);
      expect(restored.en.crystals, 6);
      expect(restored.ru.crystalsEarned, 3);
      expect(restored.en.crystalsEarned, 3);
      expect(restored.ru.completed, {1});
      expect(restored.en.completed, {1});
    },
  );

  test(
    'Endless pools, active words, histories and rewards stay independent',
    () async {
      final ru = await LevelRepository().load();
      final en = await LevelRepository().load(GameLanguage.en);
      CampaignProgress finished() => CampaignProgress(
        currentLevel: 150,
        completed: {for (var i = 1; i <= 150; i++) i},
        campaignFinalSeen: true,
      );
      final profiles = GameProfiles(
        ru: finished(),
        en: finished(),
        crystals: 20,
      );
      final ruId = profiles.ru.startEndless(ru, random: Random(11));
      final ruSource = ru.firstWhere((level) => level.id == ruId);
      profiles.ru.recordEndlessWord(ruSource, ruSource.words.first.text);
      expect(profiles.ru.recordEndlessHint(), isTrue);
      profiles.ru.recordEndlessRevealedHintCell('0:0');
      profiles.select(GameLanguage.en);
      final recent = <int>[];
      for (var round = 0; round < 12; round++) {
        final id = profiles.en.startEndless(en, random: Random(round));
        expect(recent, isNot(contains(id)));
        final source = en.firstWhere((level) => level.id == id);
        for (final word in source.words) {
          expect(word.text, matches(RegExp(r'^[A-Z]+$')));
          profiles.en.recordEndlessWord(source, word.text);
        }
        expect(profiles.en.completeEndless(source), isTrue);
        expect(profiles.en.completeEndless(source), isFalse);
        recent.add(id);
        if (recent.length > 10) recent.removeAt(0);
      }
      profiles.select(GameLanguage.ru);
      await ProgressRepository().saveProfiles(profiles);
      final restored = await ProgressRepository().loadProfiles();
      expect(restored.crystals, 46);
      expect(restored.ru.activeEndlessSourceLevelId, ruId);
      expect(restored.ru.endlessFoundWords, {ruSource.words.first.text});
      expect(restored.ru.endlessRevealedHintCells, {'0:0'});
      expect(restored.ru.endlessRoundsCompleted, 0);
      expect(restored.en.endlessRoundsCompleted, 12);
      expect(restored.en.recentEndlessSourceLevelIds, recent);
      expect(restored.ru.recentEndlessSourceLevelIds, [ruId]);
      expect(restored.ru.currentLevel, 150);
      expect(restored.en.currentLevel, 150);
    },
  );

  test(
    'English 149 → 150 completes its campaign and achievement exactly once',
    () async {
      final en = await LevelRepository().load(GameLanguage.en);
      final profiles = GameProfiles(
        en: CampaignProgress(
          currentLevel: 149,
          completed: {for (var id = 1; id <= 148; id++) id},
        ),
        selectedLanguage: GameLanguage.en,
        crystals: 10,
      );
      expect(profiles.en.complete(en[148]), isTrue);
      expect(profiles.en.currentLevel, 150);
      expect(profiles.en.campaignCompleted, isFalse);
      expect(profiles.en.complete(en[149]), isTrue);
      expect(profiles.en.currentLevel, 150);
      expect(profiles.en.campaignCompleted, isTrue);
      expect(profiles.en.crystals, 16);
      AchievementRules.unlockNew(profiles.en, en, DateTime.utc(2026));
      expect(profiles.en.unlockedAt, contains('cross_slow'));
      expect(profiles.ru.unlockedAt, isEmpty);
      expect(profiles.ru.completed, isEmpty);
      expect(profiles.en.complete(en[149]), isFalse);
      expect(profiles.en.crystals, 16);
      expect(profiles.en.campaignFinalSeen, isFalse);
      profiles.en.campaignFinalSeen = true;
      await ProgressRepository().saveProfiles(profiles);
      final restored = await ProgressRepository().loadProfiles();
      expect(restored.en.campaignFinalSeen, isTrue);
      expect(restored.en.campaignCompleted, isTrue);
      expect(restored.en.currentLevel, 150);
      expect(restored.crystals, 16);
    },
  );

  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(const CrossSlowApp());
    await tester.runAsync(() async {
      await LevelRepository().load();
      await LevelRepository().load(GameLanguage.en);
      await precacheImage(
        const AssetImage('doc/load.png'),
        tester.element(find.byType(SplashScreen)),
      );
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  }

  Future<void> selectLanguage(WidgetTester tester, GameLanguage choice) async {
    final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    home.onMenu!(tester.element(find.byType(HomeScreen)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Язык кроссвордов'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester
          .widget<MenuScreen>(find.byType(MenuScreen, skipOffstage: false))
          .englishAvailable,
      isTrue,
    );
    await tester.tap(find.text(choice.label));
    await tester.runAsync(() => LevelRepository().load(choice));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  testWidgets(
    'menu switches RU → EN → RU → EN and resumes both games after restart',
    (tester) async {
      final ru = await tester.runAsync(() => LevelRepository().load());
      final en = await tester.runAsync(
        () => LevelRepository().load(GameLanguage.en),
      );
      final ruLevel = ru![75];
      final enLevel = en![3];
      final profiles = GameProfiles(
        ru: CampaignProgress(
          currentLevel: 76,
          crystals: 30,
          foundWords: {
            76: {ruLevel.words.first.text},
          },
          revealedHintCells: {
            76: {'0:0'},
          },
          seenScenes: {'mountains_04'},
          unlockedAt: {'ru_only': DateTime.utc(2026)},
        ),
        en: CampaignProgress(
          currentLevel: 4,
          foundWords: {
            4: {enLevel.words.first.text},
          },
          revealedHintCells: {
            4: {'0:1'},
          },
          seenScenes: {'forest_01'},
          unlockedAt: {'en_only': DateTime.utc(2026)},
        ),
      );
      await ProgressRepository().saveProfiles(profiles);
      await SharedPreferencesAsync().setBool('light_theme', true);
      await boot(tester);
      expect(
        tester.widget<HomeScreen>(find.byType(HomeScreen)).language,
        GameLanguage.ru,
      );
      await selectLanguage(tester, GameLanguage.en);
      var home = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(home.language, GameLanguage.en);
      expect(home.level, 4);
      expect(home.crystals, 30);
      home.onContinue();
      await tester.pump();
      var game = tester.widget<GameScreen>(find.byType(GameScreen));
      expect(game.initialFound, {enLevel.words.first.text});
      expect(game.initialRevealed, {'0:1'});
      game.onBack();
      await tester.pump();
      await selectLanguage(tester, GameLanguage.ru);
      home = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(home.level, 76);
      home.onContinue();
      await tester.pump();
      game = tester.widget<GameScreen>(find.byType(GameScreen));
      expect(game.language, GameLanguage.ru);
      expect(game.initialFound, {ruLevel.words.first.text});
      expect(game.initialRevealed, {'0:0'});
      game.onBack();
      await tester.pump();
      await selectLanguage(tester, GameLanguage.en);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await boot(tester);
      home = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(home.language, GameLanguage.en);
      expect(home.level, 4);
      final saved = await ProgressRepository().loadProfiles();
      expect(saved.ru.unlockedAt.keys, ['ru_only']);
      expect(saved.en.unlockedAt.keys, ['en_only']);
      expect(saved.crystals, 30);
    },
  );

  testWidgets(
    'new English profile opens Home and shows its first scene once on play',
    (tester) async {
      await ProgressRepository().saveProfiles(
        GameProfiles(
          ru: CampaignProgress(crystals: 7, seenScenes: {'forest_01'}),
        ),
      );
      await boot(tester);
      await selectLanguage(tester, GameLanguage.en);
      final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(home.language, GameLanguage.en);
      expect(home.level, 1);
      expect(home.crystals, 7);
      expect(find.byType(ChapterSceneRevealScreen), findsNothing);
      home.onContinue();
      await tester.pump();
      expect(find.byType(ChapterSceneRevealScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('ПРОДОЛЖИТЬ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(HomeScreen), findsOneWidget);
      final restored = await ProgressRepository().loadProfiles();
      expect(restored.en.seenScenes, {'forest_01'});
      expect(restored.ru.seenScenes, {'forest_01'});
      expect(restored.ru.currentLevel, 1);
      expect(restored.en.currentLevel, 1);
    },
  );

  testWidgets('English Endless uses English GameScreen and north_05', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final profiles = GameProfiles(
      ru: CampaignProgress(currentLevel: 76),
      en: CampaignProgress(
        currentLevel: 150,
        completed: {for (var i = 1; i <= 150; i++) i},
        campaignFinalSeen: true,
        seenScenes: {'north_05'},
      ),
      selectedLanguage: GameLanguage.en,
      crystals: 19,
    );
    await ProgressRepository().saveProfiles(profiles);
    await boot(tester);
    tester.widget<HomeScreen>(find.byType(HomeScreen)).onContinue();
    await tester.pump();
    final game = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(game.language, GameLanguage.en);
    expect(game.endlessRound, 1);
    expect(game.sceneOverride?.id, 'north_05');
    expect(game.level.id, inInclusiveRange(50, 150));
    expect(
      game.level.words.every((w) => RegExp(r'^[A-Z]+$').hasMatch(w.text)),
      isTrue,
    );
    expect(find.text('БЕСКОНЕЧНАЯ ИГРА'), findsOneWidget);
    expect(find.text('УРОВЕНЬ ${game.level.id}'), findsNothing);
    final restored = await ProgressRepository().loadProfiles();
    expect(restored.ru.currentLevel, 76);
    expect(restored.en.currentLevel, 150);
    expect(restored.en.activeEndlessSourceLevelId, game.level.id);
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
    const Size(1200, 800),
  ]) {
    testWidgets('largest English crossword fits ${size.width}×${size.height}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final levels = await tester.runAsync(
        () => LevelRepository().load(GameLanguage.en),
      );
      final largest = levels!.reduce(
        (a, b) => a.rows * a.cols >= b.rows * b.cols ? a : b,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: largest,
            language: GameLanguage.en,
            onBack: () {},
            onComplete: () {},
            onNext: () {},
            hasNext: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(GameScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
