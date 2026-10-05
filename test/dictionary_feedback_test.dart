import 'package:cross_slow/features/game/controller/game_controller.dart';
import 'package:cross_slow/features/game/data/game_dictionary.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/game/models/level.dart';
import 'package:cross_slow/features/game/widgets/letter_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const level = Level(
    id: 999,
    letters: ['К', 'О', 'Т'],
    words: [WordPlacement(text: 'КОТ', row: 0, col: 0, down: false)],
  );

  test('game dictionary asset is loaded once and normalized', () async {
    final first = await GameDictionary.load();
    final second = await GameDictionary.load();
    expect(identical(first, second), isTrue);
    expect(first.length, greaterThan(2000));
    expect(first, containsAll(['КОТ', 'ТОК', 'КОЗЕЛ']));
    for (final excluded in [
      'ДРОВА',
      'ОСТАНКИ',
      'СУТКИ',
      'ДЖИНСЫ',
      'ДЖУНГЛИ',
      'КАНДАЛЫ',
      'КАЧЕЛИ',
      'НЕДРА',
      'НОЖНИЦЫ',
      'ПЕРИЛА',
      'ХЛОПОТЫ',
      'ЯСЛИ',
    ]) {
      expect(first, isNot(contains(excluded)));
    }
    expect(GameDictionary.normalize(' козёл '), 'КОЗЕЛ');
  });

  test(
    'required, repeated, valid outside, and unknown have distinct results',
    () {
      final controller = GameController(level, dictionary: {'КОТ', 'ТОК'});
      expect(controller.submit('КОТ'), WordResult.correct);
      expect(controller.submit('кот'), WordResult.alreadyFound);
      expect(controller.submit('ТОК'), WordResult.validNotInCrossword);
      expect(controller.submit('КТО'), WordResult.unknown);
      expect(controller.found, {'КОТ'});
      controller.dispose();
    },
  );

  test('Е and Ё are equivalent for required and dictionary-only words', () {
    const yoLevel = Level(
      id: 1000,
      letters: ['К', 'О', 'З', 'Е', 'Л'],
      words: [WordPlacement(text: 'КОЛ', row: 0, col: 0, down: false)],
    );
    final controller = GameController(yoLevel, dictionary: {'КОЗЕЛ'});
    expect(controller.submit('козёл'), WordResult.validNotInCrossword);
    controller.dispose();
    const required = Level(
      id: 1001,
      letters: ['О', 'Р', 'Е', 'Л'],
      words: [WordPlacement(text: 'ОРЕЛ', row: 0, col: 0, down: false)],
    );
    final requiredController = GameController(required);
    expect(requiredController.submit('орёл'), WordResult.correct);
    requiredController.dispose();
  });

  testWidgets('Game Screen shows neutral feedback for a valid extra word', (
    tester,
  ) async {
    await tester.runAsync(() => GameDictionary.load());
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: level,
          onBack: () {},
          onComplete: () {},
          onNext: () {},
          hasNext: false,
        ),
      ),
    );
    final board = tester.getRect(find.byType(LetterBoard));
    Future<void> drag(List<Offset> points) async {
      final gesture = await tester.startGesture(board.topLeft + points.first);
      for (final point in points.skip(1)) {
        await gesture.moveTo(board.topLeft + point);
      }
      await gesture.up();
      await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
    }

    final side = board.width;
    await drag([
      Offset(side * .76, side * .72),
      Offset(side * .24, side * .72),
      Offset(side * .5, side * .2),
    ]);
    expect(find.text('СЛОВО ЕСТЬ! НО НЕ В ЭТОМ КРОССВОРДЕ'), findsOneWidget);
    expect(
      tester.state<LetterBoardState>(find.byType(LetterBoard)).reaction,
      LetterBoardReaction.neutral,
    );
    await drag([Offset(side * .5, side * .2), Offset(side * .24, side * .72)]);
    expect(find.text('ПОПРОБУЙТЕ ЕЩЁ'), findsOneWidget);
    expect(
      tester.state<LetterBoardState>(find.byType(LetterBoard)).reaction,
      LetterBoardReaction.wrong,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
  });
}
