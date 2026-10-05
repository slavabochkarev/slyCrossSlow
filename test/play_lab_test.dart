import 'dart:ui' show PointerDeviceKind;

import 'package:cross_slow/core/theme/game_theme.dart';
import 'package:cross_slow/core/widgets/pixel_ui.dart';
import 'package:cross_slow/dev/crossword_play_lab.dart';
import 'package:cross_slow/dev/play_lab_levels.dart';
import 'package:cross_slow/features/game/controller/game_controller.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/game/widgets/crossword_board.dart';
import 'package:cross_slow/features/game/widgets/crossword_layout.dart';
import 'package:cross_slow/features/game/widgets/letter_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every Play Lab level has the requested words and can be completed', () {
    expect(playLabLevels, hasLength(11));
    for (var index = 0; index < playLabLevels.length; index++) {
      final level = playLabLevels[index];
      expect(level.words, hasLength(index + 8));
      expect(level.letters.length, inInclusiveRange(6, 7));
      final controller = GameController(level);
      for (final placement in level.words) {
        final remaining = [...level.letters];
        for (final letter in placement.text.split('')) {
          expect(
            remaining.remove(letter),
            isTrue,
            reason: '${placement.text} uses a missing or repeated letter',
          );
        }
        expect(controller.submit(placement.text), WordResult.correct);
      }
      expect(controller.completed, isTrue);
      controller.dispose();
    }
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
    const Size(1024, 768),
  ]) {
    for (final level in playLabLevels) {
      testWidgets(
        '${level.words.length} words fit ${size.width}×${size.height}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          CrosswordLayoutDiagnostics? diagnostics;
          await tester.pumpWidget(
            MaterialApp(
              theme: GameTheme.dark,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  padding: size.width < 760
                      ? const EdgeInsets.only(top: 24, bottom: 24)
                      : EdgeInsets.zero,
                ),
                child: GameScreen(
                  level: level,
                  onBack: () {},
                  onComplete: () {},
                  onNext: () {},
                  hasNext: true,
                  onCrosswordLayout: (value) => diagnostics = value,
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.byType(CrosswordBoard), findsOneWidget);
          expect(find.byType(LetterBoard), findsOneWidget);
          expect(find.byType(Scrollable), findsNothing);
          expect(diagnostics!.cols, level.cols);
          expect(diagnostics!.rows, level.rows);
          expect(diagnostics!.cellSize, greaterThan(0));
          expect(
            tester.getSize(find.byType(LetterBoard)),
            const Size(270, 270),
          );
          final shuffle = tester.getSize(
            find.ancestor(
              of: find.byIcon(Icons.shuffle),
              matching: find.byType(PixelButton),
            ),
          );
          expect(shuffle.width, greaterThanOrEqualTo(44));
          expect(shuffle.height, greaterThanOrEqualTo(44));
          expect(find.text('ПЕРЕМЕШАТЬ'), findsNothing);
        },
      );
    }
  }

  testWidgets(
    'mouse drag completes a real Play Lab crossword and shuffle works',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final level = playLabLevels.first;
      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: GameTheme.dark,
          home: GameScreen(
            level: level,
            onBack: () {},
            onComplete: () => completions++,
            onNext: () {},
            hasNext: true,
          ),
        ),
      );
      final state = tester.state<LetterBoardState>(find.byType(LetterBoard));
      final original = List<int>.of(state.order);
      for (
        var attempt = 0;
        attempt < 5 && state.order.join() == original.join();
        attempt++
      ) {
        await tester.tap(find.byIcon(Icons.shuffle));
        await tester.pump(const Duration(milliseconds: 350));
      }
      expect(state.order.join(), isNot(original.join()));

      // Restore the original order through the widget lifecycle before dragging.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          theme: GameTheme.dark,
          home: GameScreen(
            level: level,
            onBack: () {},
            onComplete: () => completions++,
            onNext: () {},
            hasNext: true,
          ),
        ),
      );
      for (final placement in level.words) {
        final rect = tester.getRect(find.byType(LetterBoard));
        final buttons = tester
            .widgetList<AnimatedPositioned>(
              find.descendant(
                of: find.byType(LetterBoard),
                matching: find.byType(AnimatedPositioned),
              ),
            )
            .toList();
        final remaining = List<int>.generate(level.letters.length, (i) => i);
        final points = <Offset>[];
        for (final letter in placement.text.split('')) {
          final id = remaining.firstWhere((i) => level.letters[i] == letter);
          remaining.remove(id);
          points.add(
            rect.topLeft +
                Offset(
                  buttons[id].left! + buttons[id].width! / 2,
                  buttons[id].top! + buttons[id].height! / 2,
                ),
          );
        }
        final gesture = await tester.startGesture(
          points.first,
          kind: PointerDeviceKind.mouse,
        );
        for (final point in points.skip(1)) {
          await gesture.moveTo(point);
        }
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 650));
      }
      expect(completions, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('УРОВЕНЬ ПРОЙДЕН'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Play Lab cycles across all eleven levels', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const CrosswordPlayLab());
    for (final level in playLabLevels) {
      final label =
          '${level.words.length} слов · ${level.cols}×${level.rows}  ›';
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pump();
    }
    expect(find.textContaining('8 слов'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
