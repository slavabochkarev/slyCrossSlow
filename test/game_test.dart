import 'package:cross_slow/features/game/controller/game_controller.dart';
import 'package:cross_slow/features/game/data/level_repository.dart';
import 'package:cross_slow/features/game/widgets/letter_board.dart';
import 'package:cross_slow/core/widgets/pixel_ui.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/game/models/level.dart';
import 'package:cross_slow/features/home/home_screen.dart';
import 'package:cross_slow/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash uses the supplied loading artwork', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, const AssetImage('doc/load.png'));
  });

  test('every word can be made from its level letters', () async {
    final levels = await LevelRepository().load();
    expect(levels.length, 3);
    for (final level in levels) {
      for (final word in level.words) {
        final available = [...level.letters];
        for (final letter in word.text.split('')) {
          expect(
            available.contains(letter),
            isTrue,
            reason: 'Level ${level.id}: ${word.text}',
          );
          available.remove(letter);
        }
      }
      final controller = GameController(level);
      for (final word in level.words) {
        expect(controller.submit(word.text), WordResult.correct);
      }
      expect(controller.completed, isTrue);
    }
  });

  testWidgets('dragging across physical letter positions submits a word', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              height: 200,
              child: LetterBoard(
                letters: const ['К', 'О', 'Т'],
                onWord: (word) => submitted = word,
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    final topLeft = tester.getTopLeft(find.byType(LetterBoard));
    final gesture = await tester.startGesture(topLeft + const Offset(130, 34));
    await gesture.moveTo(topLeft + const Offset(52, 152));
    await gesture.moveTo(topLeft + const Offset(208, 152));
    await gesture.up();
    expect(submitted, 'КОТ');
  });

  testWidgets(
    'accepted word reveals cells in sequence and hint skips crossings',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const level = Level(
        id: 1,
        letters: ['К', 'О', 'Т'],
        words: [
          WordPlacement(text: 'КОТ', row: 0, col: 0, down: false),
          WordPlacement(text: 'ТОК', row: 0, col: 2, down: true),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: level,
            onBack: () {},
            onComplete: () {},
            onNext: () {},
            hasNext: true,
          ),
        ),
      );
      int openCount() => tester
          .widgetList<PixelCell>(find.byType(PixelCell))
          .where((cell) => cell.open)
          .length;
      final board = find.byType(LetterBoard);
      final origin = tester.getTopLeft(board);
      final size = tester.getSize(board);
      final gesture = await tester.startGesture(
        origin + Offset(size.width * .5, size.height * .19),
      );
      await gesture.moveTo(origin + Offset(size.width * .2, size.height * .74));
      await gesture.moveTo(origin + Offset(size.width * .8, size.height * .74));
      await gesture.up();
      await tester.pump();
      expect(openCount(), 0);
      await tester.pump(const Duration(milliseconds: 145));
      expect(openCount(), 1);
      await tester.pump(const Duration(milliseconds: 180));
      expect(openCount(), 3);
      await tester.tap(find.text('10 💎'));
      await tester.pump();
      expect(openCount(), 4);
      await tester.pump(const Duration(seconds: 2));
    },
  );

  for (final size in [const Size(390, 700), const Size(1100, 700)]) {
    testWidgets('home and game fit ${size.width}x${size.height}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            level: 1,
            totalLevels: 3,
            completed: 0,
            onContinue: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      const level = Level(
        id: 1,
        letters: ['К', 'О', 'Т'],
        words: [WordPlacement(text: 'КОТ', row: 0, col: 0, down: false)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: level,
            onBack: () {},
            onComplete: () {},
            onNext: () {},
            hasNext: true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final boardSize = tester.getSize(find.byType(LetterBoard));
      expect((boardSize.width - boardSize.height).abs(), lessThan(1));
    });
  }
}
