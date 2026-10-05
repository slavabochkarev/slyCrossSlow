import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_slow/core/theme/game_theme.dart';
import 'package:cross_slow/core/widgets/pixel_ui.dart';
import 'package:cross_slow/dev/crossword_size_lab.dart';
import 'package:cross_slow/dev/size_lab_levels.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/game/widgets/crossword_board.dart';
import 'package:cross_slow/features/game/widgets/crossword_layout.dart';
import 'package:cross_slow/features/game/widgets/letter_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    var directory = File(Platform.resolvedExecutable).parent;
    Directory? fonts;
    while (true) {
      final candidate = Directory(
        '${directory.path}/bin/cache/artifacts/material_fonts',
      );
      if (candidate.existsSync()) {
        fonts = candidate;
        break;
      }
      if (directory.parent.path == directory.path) break;
      directory = directory.parent;
    }
    if (fonts == null) {
      throw StateError('Flutter material_fonts directory not found');
    }
    Future<ByteData> font(String name) async =>
        ByteData.sublistView(await File('${fonts!.path}/$name').readAsBytes());
    await (FontLoader('Roboto')..addFont(font('roboto-regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(font('materialicons-regular.otf'))).load();
  });

  final sizes = <Size>[
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
    const Size(1024, 768),
    const Size(1200, 800),
  ];

  for (final size in sizes) {
    for (var index = 0; index < sizeLabLevels.length; index++) {
      final level = sizeLabLevels[index];
      testWidgets('${level.cols}×${level.rows} fits ${size.width}×${size.height}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final screenshotKey = GlobalKey();
        CrosswordLayoutDiagnostics? layout;
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
              child: RepaintBoundary(
                key: screenshotKey,
                child: GameScreen(
                  level: level,
                  onBack: () {},
                  onComplete: () {},
                  onNext: () {},
                  hasNext: true,
                  devPreviewWord: sizeLabNames[index],
                  revealCrosswordForSizeLab: true,
                  onCrosswordLayout: (value) => layout = value,
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            AssetImage(
              size.width >= 760
                  ? 'assets/backgrounds/forest_wide.png'
                  : 'assets/backgrounds/forest_portrait.png',
            ),
            screenshotKey.currentContext!,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
        expect(layout, isNotNull);
        expect(layout!.rows, level.rows);
        expect(layout!.cols, level.cols);
        expect(find.byType(CrosswordBoard), findsOneWidget);
        expect(find.byType(LetterBoard), findsOneWidget);
        expect(find.byIcon(Icons.shuffle), findsOneWidget);
        expect(find.text('ПЕРЕМЕШАТЬ'), findsNothing);
        expect(find.byIcon(Icons.lightbulb), findsOneWidget);
        expect(find.byType(Scrollable), findsNothing);

        final header = tester.getRect(find.text('УРОВЕНЬ ${level.id}'));
        final board = tester.getRect(find.byType(CrosswordBoard));
        final currentWord = tester.getRect(find.text(sizeLabNames[index]));
        final letters = tester.getRect(find.byType(LetterBoard));
        final shuffle = tester.getRect(
          find.ancestor(
            of: find.byIcon(Icons.shuffle),
            matching: find.byType(PixelButton),
          ),
        );
        final hint = tester.getRect(find.byIcon(Icons.lightbulb));
        final hintButton = tester.getRect(
          find.ancestor(
            of: find.byIcon(Icons.lightbulb),
            matching: find.byType(PixelButton),
          ),
        );
        expect(board.top, greaterThan(header.bottom));
        if (size.width < 760) {
          expect(currentWord.top, greaterThanOrEqualTo(board.bottom));
          expect(letters.top, greaterThan(currentWord.bottom));
        }
        expect(shuffle.top, lessThan(letters.bottom));
        expect(hintButton.top, lessThan(letters.bottom));
        expect(shuffle.bottom, lessThanOrEqualTo(letters.bottom));
        expect(hintButton.bottom, lessThanOrEqualTo(letters.bottom));
        expect(hint.bottom, lessThanOrEqualTo(size.height));
        expect(shuffle.height, greaterThanOrEqualTo(36));
        expect(hintButton.height, greaterThanOrEqualTo(36));
        expect(letters.width, greaterThanOrEqualTo(200));
        expect(letters.height, greaterThanOrEqualTo(200));

        final output = File(
          'tools/size_lab/screenshots/${size.width.toInt()}x${size.height.toInt()}_${level.cols}x${level.rows}.png',
        );
        await tester.runAsync(() async {
          final image =
              await (screenshotKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        debugPrint(
          '${size.width.toInt()}×${size.height.toInt()} | ${layout!.report} | LetterBoard ${letters.width.toStringAsFixed(1)}×${letters.height.toStringAsFixed(1)} | Shuffle ${shuffle.width.toStringAsFixed(1)}×${shuffle.height.toStringAsFixed(1)} | Hint ${hintButton.width.toStringAsFixed(1)}×${hintButton.height.toStringAsFixed(1)} | screenshot ${output.path}',
        );
      });
    }
  }

  testWidgets('seven letters form a ring without a central letter', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: GameTheme.dark,
        home: GameScreen(
          level: sizeLabLevels[1],
          onBack: () {},
          onComplete: () {},
          onNext: () {},
          hasNext: true,
        ),
      ),
    );
    final board = tester.getRect(find.byType(LetterBoard));
    final letters = tester
        .widgetList<AnimatedPositioned>(
          find.descendant(
            of: find.byType(LetterBoard),
            matching: find.byType(AnimatedPositioned),
          ),
        )
        .toList();
    expect(letters, hasLength(7));
    final distances = letters.map((letter) {
      final dx = letter.left! + letter.width! / 2 - board.width / 2;
      final dy = letter.top! + letter.height! / 2 - board.height / 2;
      expect(letter.width, lessThanOrEqualTo(56));
      return Offset(dx, dy).distance;
    }).toList();
    expect(distances.reduce((a, b) => a < b ? a : b), greaterThan(70));
    expect(
      distances.reduce((a, b) => a > b ? a : b) -
          distances.reduce((a, b) => a < b ? a : b),
      lessThan(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('developer Game Screen cycles through all real boards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const CrosswordSizeLab());
    for (final label in [
      '6×6  ›',
      '7×7  ›',
      '8×8  ›',
      '10×10  ›',
      '7×8  ›',
      '8×9  ›',
      '8×10  ›',
    ]) {
      expect(find.text(label), findsOneWidget);
      expect(find.byType(CrosswordBoard), findsOneWidget);
      expect(find.byType(LetterBoard), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pump();
    }
    expect(find.text('6×6  ›'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(find.text('8×10  ›'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
