import 'package:cross_slow/campaign/chapter_ambient_effects.dart';
import 'package:cross_slow/campaign/chapter_scene.dart';
import 'package:cross_slow/campaign/chapter_scene_backdrop.dart';
import 'package:cross_slow/core/theme/game_theme.dart';
import 'package:cross_slow/core/widgets/scenic_background.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/game/models/level.dart';
import 'package:cross_slow/features/game/widgets/letter_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sly_fl_effects_lab/effects/sly_fl_effects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Level level(int id) => Level(
    id: id,
    letters: const ['К', 'О', 'Т'],
    words: const [WordPlacement(text: 'КОТ', row: 0, col: 0, down: false)],
  );

  Widget game(int id, {bool light = false}) => MaterialApp(
    theme: light ? GameTheme.light : GameTheme.dark,
    home: GameScreen(
      level: level(id),
      onBack: () {},
      onComplete: () {},
      onNext: () {},
      hasNext: true,
    ),
  );

  for (final id in [
    1,
    7,
    8,
    11,
    14,
    15,
    18,
    20,
    21,
    27,
    28,
    34,
    35,
    42,
    43,
    50,
    51,
    57,
    58,
    64,
    65,
    72,
    73,
    80,
    81,
    87,
    88,
    94,
    95,
    102,
    103,
    110,
    111,
    118,
    119,
    126,
    127,
    134,
    135,
    142,
    143,
    150,
  ]) {
    testWidgets('game level $id uses the Home chapter scene', (tester) async {
      await tester.pumpWidget(game(id));
      final scene = ChapterScenes.forLevel(id)!;
      final backdrop = tester.widget<ChapterSceneBackdrop>(
        find.byType(ChapterSceneBackdrop),
      );
      expect(backdrop.scene, same(scene));
      expect(backdrop.ambientEffects, isFalse);
      expect(find.byType(ChapterAmbientEffects), findsNothing);
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byType(ChapterSceneBackdrop),
          matching: find.byType(Image),
        ),
      );
      expect(image.image, AssetImage(scene.backgroundAsset));
      expect(image.fit, BoxFit.cover);
      expect(image.alignment, scene.focalAlignment);
      expect(find.byIcon(Icons.lightbulb), findsOneWidget);
      expect(find.text('10'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scene stays the same in light theme', (tester) async {
    await tester.pumpWidget(game(11, light: true));
    expect(
      tester
          .widget<ChapterSceneBackdrop>(find.byType(ChapterSceneBackdrop))
          .scene,
      same(ChapterScenes.forLevel(11)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('out-of-campaign levels retain the existing Game background', (
    tester,
  ) async {
    await tester.pumpWidget(game(151));
    expect(find.byType(ScenicBackground), findsOneWidget);
    expect(find.byType(ChapterSceneBackdrop), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('victory confetti paints above the victory panel', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(game(1));
    final board = find.byType(LetterBoard);
    final origin = tester.getTopLeft(board);
    final size = tester.getSize(board);
    final gesture = await tester.startGesture(
      origin + Offset(size.width * .5, size.height * .19),
    );
    await gesture.moveTo(origin + Offset(size.width * .2, size.height * .74));
    await gesture.moveTo(origin + Offset(size.width * .8, size.height * .74));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('ПРОДОЛЖИТЬ ИГРАТЬ'), findsOneWidget);
    expect(find.byType(ChapterSceneBackdrop), findsOneWidget);
    final effect = find.byType(EffectPlayer);
    expect(effect, findsOneWidget);
    final overlay = tester.widget<Stack>(
      find.ancestor(of: effect, matching: find.byType(Stack)).first,
    );
    final topLayer = overlay.children.last as Positioned;
    expect((topLayer.child as IgnorePointer).child, isA<EffectPlayer>());
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
  });
}
