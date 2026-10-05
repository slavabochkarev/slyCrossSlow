import 'dart:math';

import 'package:cross_slow/features/game/data/level_repository.dart';
import 'package:cross_slow/features/game/models/level.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/home/home_screen.dart';
import 'package:cross_slow/campaign/chapter_scene.dart';
import 'package:cross_slow/progress/campaign_progress.dart';
import 'package:cross_slow/progress/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Level> widgetLevels;
  setUpAll(() async => widgetLevels = await LevelRepository().load());

  CampaignProgress finishedCampaign() => CampaignProgress(
    currentLevel: 150,
    completed: {for (var id = 1; id <= 150; id++) id},
    crystals: 20,
  );

  test('level 150 completes campaign without creating level 151', () async {
    final levels = await LevelRepository().load();
    final state = CampaignProgress(
      currentLevel: 150,
      completed: {for (var id = 1; id < 150; id++) id},
    );
    expect(state.complete(levels.last), isTrue);
    expect(state.campaignCompleted, isTrue);
    expect(state.currentLevel, 150);
    expect(state.completedLevels, 150);
    expect(state.crystalsEarned, 3);
    expect(state.campaignFinalSeen, isFalse);
  });

  test('endless round updates shared statistics but not campaign', () async {
    final levels = await LevelRepository().load();
    final state = finishedCampaign();
    final sourceId = state.startEndless(levels, random: Random(42));
    final source = levels.singleWhere((level) => level.id == sourceId);
    expect(state.startEndless(levels, random: Random(1)), sourceId);
    expect(state.recordEndlessHint(), isTrue);
    expect(state.crystals, 10);
    for (final word in source.words) {
      expect(state.recordEndlessWord(source, word.text), isTrue);
      expect(state.recordEndlessWord(source, word.text), isFalse);
    }
    expect(state.completeEndless(source), isTrue);
    expect(state.completeEndless(source), isFalse);
    expect(state.endlessRoundsCompleted, 1);
    expect(state.wordsFound, source.words.length);
    expect(state.hintsUsed, 1);
    expect(state.crystals, 13);
    expect(state.crystalsEarned, 3);
    expect(state.currentLevel, 150);
    expect(state.completedLevels, 150);
    expect(state.pendingChapterId, isNull);
    expect(state.activeEndlessSourceLevelId, isNull);
  });

  test('random selection excludes the last ten source levels', () async {
    final levels = await LevelRepository().load();
    final state = finishedCampaign();
    final random = Random(7);
    final played = <int>[];
    for (var round = 0; round < 18; round++) {
      final sourceId = state.startEndless(levels, random: random);
      expect(sourceId, inInclusiveRange(50, 150));
      expect(played.reversed.take(10), isNot(contains(sourceId)));
      final source = levels.singleWhere((level) => level.id == sourceId);
      for (final word in source.words) {
        state.recordEndlessWord(source, word.text);
      }
      expect(state.completeEndless(source), isTrue);
      played.add(sourceId);
      expect(state.recentEndlessSourceLevelIds.length, lessThanOrEqualTo(10));
    }
    expect(state.endlessRoundsCompleted, 18);
    expect(state.completedLevels, 150);
  });

  test('small pool relaxes recent filter', () {
    const source = Level(
      id: 50,
      letters: ['К', 'О', 'Т'],
      words: [WordPlacement(text: 'КОТ', row: 0, col: 0, down: false)],
    );
    final state = finishedCampaign()..recentEndlessSourceLevelIds.add(50);
    expect(state.startEndless([source], random: Random(1)), 50);
  });

  test('old schema 2 save migrates and active Endless round resumes', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final levels = await LevelRepository().load();
    final oldJson = finishedCampaign().toJson()
      ..remove('campaignFinalSeen')
      ..remove('endlessRoundsCompleted')
      ..remove('activeEndlessSourceLevelId')
      ..remove('endlessFoundWords')
      ..remove('endlessHinted')
      ..remove('recentEndlessSourceLevelIds');
    final migrated = CampaignProgress.fromJson(oldJson);
    expect(migrated.campaignCompleted, isTrue);
    expect(migrated.endlessRoundsCompleted, 0);
    expect(migrated.campaignFinalSeen, isFalse);

    final sourceId = migrated.startEndless(levels, random: Random(3));
    final source = levels.singleWhere((level) => level.id == sourceId);
    migrated.recordEndlessWord(source, source.words.first.text);
    await ProgressRepository().save(migrated);
    final restored = await ProgressRepository().load();
    expect(restored.campaignCompleted, isTrue);
    expect(restored.currentLevel, 150);
    expect(restored.activeEndlessSourceLevelId, sourceId);
    expect(restored.endlessFoundWords, {source.words.first.text});
    expect(restored.startEndless(levels, random: Random(99)), sourceId);
    expect(restored.recentEndlessSourceLevelIds, [sourceId]);
  });

  for (final size in [const Size(360, 800), const Size(1200, 800)]) {
    testWidgets('Endless Home and Game fit ${size.width}×${size.height}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            level: 150,
            totalLevels: 150,
            completed: 150,
            campaignCompleted: true,
            endlessRoundsCompleted: 12,
            onContinue: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.text('КРАЙ СВЕТА'), findsOneWidget);
      expect(find.text('Бесконечная игра · 12'), findsOneWidget);
      expect(find.text('ИГРАТЬ'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: widgetLevels[86],
            endlessRound: 18,
            sceneOverride: ChapterScenes.forLevel(150),
            onBack: () {},
            onComplete: () {},
            onNext: () {},
            hasNext: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.text('БЕСКОНЕЧНАЯ ИГРА'), findsOneWidget);
      expect(find.text('Раунд 18'), findsOneWidget);
      expect(find.text('УРОВЕНЬ 87'), findsNothing);
    });
  }
}
