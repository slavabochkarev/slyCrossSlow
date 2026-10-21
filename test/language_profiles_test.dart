import 'dart:convert';

import 'package:cross_slow/features/game/controller/game_controller.dart';
import 'package:cross_slow/features/game/data/game_dictionary.dart';
import 'package:cross_slow/features/game/data/level_repository.dart';
import 'package:cross_slow/features/game/models/level.dart';
import 'package:cross_slow/features/game/widgets/letter_board.dart';
import 'package:cross_slow/features/menu/menu_screen.dart';
import 'package:cross_slow/game_language.dart';
import 'package:cross_slow/progress/campaign_progress.dart';
import 'package:cross_slow/progress/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('old Russian v2 state migrates exactly and only once', () async {
    final old = CampaignProgress(
      currentLevel: 76,
      completed: {for (var level = 1; level <= 75; level++) level},
      crystals: 47,
      wordsFound: 580,
      hintsUsed: 9,
      levelsWithoutHints: 68,
      currentStreak: 5,
      bestStreak: 18,
      crystalsEarned: 225,
      foundWords: {
        76: {'КОТ'},
      },
      revealedHintCells: {
        76: {'1:2'},
      },
      hintedLevels: {76},
      unlockedAt: {'first_step': DateTime.utc(2026, 1, 2)},
      seenScenes: {'forest_01', 'forest_02'},
      pendingChapterId: 3,
      recentEndlessSourceLevelIds: [50, 51],
    );
    final preferences = SharedPreferencesAsync();
    final oldJson = jsonEncode(old.toJson());
    await preferences.setString(ProgressRepository.stateKey, oldJson);

    final repository = ProgressRepository();
    final first = await repository.loadProfiles();
    expect(first.ru.toJson(), old.toJson());
    expect(first.en.currentLevel, 1);
    expect(first.crystals, 47);
    expect(first.selectedLanguage, GameLanguage.ru);
    expect(await preferences.getString(ProgressRepository.stateKey), oldJson);
    final firstEnvelope = await preferences.getString(
      ProgressRepository.profilesKey,
    );

    final second = await ProgressRepository().loadProfiles();
    expect(second.ru.toJson(), old.toJson());
    expect(
      await preferences.getString(ProgressRepository.profilesKey),
      firstEnvelope,
    );
  });

  test('RU → EN → RU keeps independent progress and one balance', () async {
    final repository = ProgressRepository();
    final profiles = await repository.loadProfiles();
    profiles.ru.currentLevel = 76;
    profiles.ru.completed.addAll({1, 2, 3});
    profiles.ru.foundWords[76] = {'КОТ'};
    profiles.ru.revealedHintCells[76] = {'0:0'};
    profiles.ru.unlockedAt['first_step'] = DateTime.utc(2026, 1, 2);
    profiles.ru.crystals = 30;
    await repository.saveProfiles(profiles);

    var restored = await ProgressRepository().loadProfiles();
    restored.select(GameLanguage.en);
    restored.en.currentLevel = 4;
    restored.en.completed.addAll({1, 2, 3});
    restored.en.foundWords[4] = {'CAT'};
    restored.en.revealedHintCells[4] = {'2:1'};
    restored.en.unlockedAt['first_step'] = DateTime.utc(2026, 3, 4);
    restored.en.crystals = 20;
    await repository.saveProfiles(restored);

    restored = await ProgressRepository().loadProfiles();
    expect(restored.selectedLanguage, GameLanguage.en);
    expect(restored.en.currentLevel, 4);
    expect(restored.en.foundWords[4], {'CAT'});
    expect(restored.ru.currentLevel, 76);
    expect(restored.ru.foundWords[76], {'КОТ'});
    expect(restored.en.unlockedAt['first_step'], DateTime.utc(2026, 3, 4));
    expect(restored.ru.unlockedAt['first_step'], DateTime.utc(2026, 1, 2));
    expect(restored.crystals, 20);
    expect(restored.ru.crystals, 20);

    restored.select(GameLanguage.ru);
    await repository.saveProfiles(restored);
    final afterRestart = await ProgressRepository().loadProfiles();
    expect(afterRestart.selectedLanguage, GameLanguage.ru);
    expect(afterRestart.active.currentLevel, 76);
    expect(afterRestart.active.revealedHintCells[76], {'0:0'});
    expect(afterRestart.en.currentLevel, 4);
    expect(afterRestart.en.revealedHintCells[4], {'2:1'});
    final encoded = jsonDecode(
      (await SharedPreferencesAsync().getString(
        ProgressRepository.profilesKey,
      ))!,
    ) as Map<String, dynamic>;
    expect(encoded['crystals'], 20);
    expect((encoded['profiles'] as Map)['ru'], isNot(contains('crystals')));
    expect((encoded['profiles'] as Map)['en'], isNot(contains('crystals')));
  });

  test(
    'old completed campaign and active Endless round survive migration',
    () async {
      final old = CampaignProgress(
        currentLevel: 150,
        completed: {for (var level = 1; level <= 150; level++) level},
        crystals: 91,
        seenScenes: {'north_05'},
        campaignFinalSeen: true,
        endlessRoundsCompleted: 12,
        activeEndlessSourceLevelId: 87,
        endlessFoundWords: {'КОТ'},
        endlessRevealedHintCells: {'2:3'},
        endlessHinted: true,
        recentEndlessSourceLevelIds: [50, 67, 87],
      );
      await SharedPreferencesAsync().setString(
        ProgressRepository.stateKey,
        jsonEncode(old.toJson()),
      );
      final migrated = await ProgressRepository().loadProfiles();
      expect(migrated.ru.toJson(), old.toJson());
      expect(migrated.ru.campaignCompleted, isTrue);
      expect(migrated.ru.activeEndlessSourceLevelId, 87);
      expect(migrated.ru.endlessFoundWords, {'КОТ'});
      expect(migrated.ru.endlessRevealedHintCells, {'2:3'});
    },
  );

  test('English resources normalize A–Z and respect letter counts', () async {
    expect(GameDictionary.normalize(' козёл '), 'КОЗЕЛ');
    expect(GameDictionary.normalize(' cat ', GameLanguage.en), 'CAT');
    expect(GameDictionary.normalize('ЁЖ', GameLanguage.en), isEmpty);
    expect(GameDictionary.normalize('café', GameLanguage.en), isEmpty);
    final game = await GameDictionary.loadGameWords(GameLanguage.en);
    final recognition = await GameDictionary.load(GameLanguage.en);
    expect(game.length, 5948);
    expect(recognition.length, 27854);
    expect(recognition.containsAll(game), isTrue);
    expect(await LevelRepository().hasCampaign(GameLanguage.en), isTrue);
    final scowlNotice = await rootBundle.loadString(
      'assets/licenses/SCOWL_Copyright.txt',
    );
    expect(scowlNotice, contains('Copyright 2000-2018 by Kevin Atkinson'));

    final controller = GameController(
      const Level(
        id: 1,
        letters: ['L', 'E', 'V', 'E', 'L'],
        words: [WordPlacement(text: 'LEVEL', row: 0, col: 0, down: false)],
      ),
      language: GameLanguage.en,
      dictionary: {'EVE', 'LEVER'},
    );
    expect(controller.submit('eve'), WordResult.validNotInCrossword);
    expect(controller.submit('lever'), WordResult.unknown);
    expect(controller.submit('level'), WordResult.correct);
    controller.dispose();
  });

  testWidgets(
    'game settings own language selection and Info keeps dictionary license',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MenuScreen(
            themeMode: ThemeMode.dark,
            onThemeChanged: (_) {},
            progress: CampaignProgress(),
            levels: const [
              Level(id: 1, letters: ['К'], words: []),
            ],
          ),
        ),
      );
      expect(find.text('Язык кроссвордов'), findsOneWidget);
      await tester.tap(find.text('ИНФО'));
      await tester.pumpAndSettle();
      expect(find.text('Язык кроссвордов').hitTestable(), findsNothing);
      await tester.ensureVisible(find.text('Лицензия английского словаря'));
      expect(
        find.text('Лицензия английского словаря').hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.text('ИГРА'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Язык кроссвордов'));
      await tester.pumpAndSettle();
      expect(find.text('Русский'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(
        find.text('Доступен после добавления английских уровней'),
        findsOneWidget,
      );
    },
  );

  testWidgets('English letters use the existing drag gesture', (tester) async {
    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              height: 200,
              child: LetterBoard(
                letters: const ['C', 'A', 'T'],
                onWord: (word) => submitted = word,
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(LetterBoard));
    final gesture = await tester.startGesture(origin + const Offset(130, 34));
    await gesture.moveTo(origin + const Offset(52, 152));
    await gesture.moveTo(origin + const Offset(208, 152));
    await gesture.up();
    expect(submitted, 'CAT');
  });
}
