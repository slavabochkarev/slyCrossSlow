import 'package:cross_slow/campaign/chapter_scene.dart';
import 'package:cross_slow/campaign/chapter_scene_backdrop.dart';
import 'package:cross_slow/core/theme/game_theme.dart';
import 'package:cross_slow/core/widgets/scenic_background.dart';
import 'package:cross_slow/features/game/data/level_repository.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/game/models/level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Level> levels;
  setUpAll(() async => levels = await LevelRepository().load());

  for (final size in <Size>[
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
    const Size(1200, 800),
  ]) {
    for (final scene in ChapterScenes.all) {
      testWidgets(
        'real Game level ${scene.levelFrom} fits ${size.width}×${size.height}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final level = levels.firstWhere((item) => item.id == scene.levelFrom);
          await tester.pumpWidget(
            MaterialApp(
              theme: GameTheme.dark,
              home: GameScreen(
                level: level,
                onBack: () {},
                onComplete: () {},
                onNext: () {},
                hasNext: true,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull);
          expect(find.byType(ChapterSceneBackdrop), findsOneWidget);
          expect(find.byType(ScenicBackground), findsNothing);
        },
      );
    }
  }
}
