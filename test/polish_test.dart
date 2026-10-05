import 'dart:math';

import 'package:cross_slow/features/game/controller/game_controller.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/game/models/level.dart';
import 'package:cross_slow/features/game/widgets/letter_board.dart';
import 'package:cross_slow/features/home/home_screen.dart';
import 'package:cross_slow/core/theme/game_theme.dart';
import 'package:cross_slow/core/widgets/pixel_ui.dart';
import 'package:cross_slow/progress/progress_repository.dart';
import 'package:cross_slow/progress/campaign_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const crossingLevel = Level(
    id: 1,
    letters: ['К', 'О', 'Т'],
    words: [
      WordPlacement(text: 'КОТ', row: 0, col: 0, down: false),
      WordPlacement(text: 'ТОК', row: 0, col: 2, down: true),
    ],
  );

  test('hint selects random closed physical cells only', () {
    final firstChoices = <String>{};
    for (var seed = 0; seed < 30; seed++) {
      final controller = GameController(crossingLevel, random: Random(seed));
      expect(controller.submit('КОТ'), WordResult.correct);
      expect(controller.revealOne(), isTrue);
      firstChoices.add(controller.revealed.single);
      expect(controller.revealed.single, isIn({'1:2', '2:2'}));
      expect(controller.revealOne(), isTrue);
      expect(controller.revealed, {'1:2', '2:2'});
      expect(controller.revealOne(), isFalse);
      expect(controller.revealed.length, 2);
    }
    expect(firstChoices, {'1:2', '2:2'});
  });

  test('crystal balance survives a new repository instance', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final repository = ProgressRepository();
    final progress = CampaignProgress(
      currentLevel: 2,
      completed: {1},
      crystals: 13,
    );
    expect(progress.recordHint(2), isTrue);
    await repository.save(progress);
    final loaded = await ProgressRepository().load();
    expect(loaded.currentLevel, 2);
    expect(loaded.completed, {1});
    expect(loaded.crystals, 3);
    expect(loaded.hintsUsed, 1);
  });

  testWidgets('hint updates header balance and blocks unaffordable hint', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var balance = CampaignProgress.hintCost;
    var hints = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, update) => GameScreen(
            level: crossingLevel,
            crystals: balance,
            onHintUsed: () {
              if (balance < CampaignProgress.hintCost) return false;
              update(() {
                balance -= CampaignProgress.hintCost;
                hints++;
              });
              return true;
            },
            onBack: () {},
            onComplete: () {},
            onNext: () {},
            hasNext: true,
          ),
        ),
      ),
    );
    expect(find.text('10'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lightbulb));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('БУКВА ОТКРЫТА'), findsOneWidget);
    expect(hints, 1);

    await tester.tap(find.byIcon(Icons.lightbulb));
    await tester.pump();
    expect(find.text('НЕДОСТАТОЧНО КРИСТАЛЛОВ'), findsOneWidget);
    expect(hints, 1);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('one finished game calls completion once', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var completions = 0;
    const singleWordLevel = Level(
      id: 1,
      letters: ['К', 'О', 'Т'],
      words: [WordPlacement(text: 'КОТ', row: 0, col: 0, down: false)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: singleWordLevel,
          onBack: () {},
          onComplete: () => completions++,
          onNext: () {},
          hasNext: true,
        ),
      ),
    );
    final board = find.byType(LetterBoard);
    final origin = tester.getTopLeft(board);
    final size = tester.getSize(board);
    Future<void> dragWord() async {
      final gesture = await tester.startGesture(
        origin + Offset(size.width * .5, size.height * .19),
      );
      await gesture.moveTo(origin + Offset(size.width * .2, size.height * .74));
      await gesture.moveTo(origin + Offset(size.width * .8, size.height * .74));
      await gesture.up();
      await tester.pump();
    }

    await dragWord();
    expect(completions, 1);
    await dragWord();
    expect(completions, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('ПРОДОЛЖИТЬ ИГРАТЬ'), findsOneWidget);
    expect(find.byType(CrystalIcon), findsNWidgets(2));
  });

  for (final size in [const Size(390, 700), const Size(1100, 700)]) {
    for (final light in [false, true]) {
      testWidgets(
        'home hierarchy fits ${size.width}x${size.height} in ${light ? 'light' : 'dark'}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              theme: light ? GameTheme.light : GameTheme.dark,
              home: HomeScreen(
                level: 2,
                totalLevels: 3,
                completed: 1,
                crystals: 3,
                onContinue: () {},
              ),
            ),
          );
          final logo = find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName == 'doc/logo.png',
          );
          final button = find.widgetWithText(PixelButton, 'ПРОДОЛЖИТЬ');
          expect(logo, findsOneWidget);
          expect(
            tester.getTopLeft(logo).dx + tester.getSize(logo).width / 2,
            closeTo(size.width / 2, 1),
          );
          expect(
            tester.getTopLeft(logo).dy,
            lessThan(tester.getTopLeft(find.text('УРОВЕНЬ 2')).dy),
          );
          expect(
            tester.getTopLeft(button).dy,
            greaterThan(tester.getBottomLeft(find.text('2 / 20')).dy),
          );
          expect(
            tester.getSize(button).width,
            lessThanOrEqualTo(size.width < 740 ? 300 : 340),
          );
          expect(tester.widget<PixelButton>(button).borderRadius, 30);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
