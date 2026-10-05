import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_slow/core/theme/game_theme.dart';
import 'package:cross_slow/campaign/chapter_scene.dart';
import 'package:cross_slow/features/home/home_screen.dart';
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
    if (fonts == null) throw StateError('Flutter material_fonts not found');
    Future<ByteData> font(String name) async =>
        ByteData.sublistView(await File('${fonts!.path}/$name').readAsBytes());
    await (FontLoader('Roboto')..addFont(font('roboto-regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(font('materialicons-regular.otf'))).load();
  });

  for (final (size, suffix) in <(Size, String)>[
    (const Size(390, 844), 'portrait'),
    (const Size(1200, 800), 'wide'),
  ]) {
    for (final light in [false, true]) {
      for (final level in [1, 8, 15]) {
        testWidgets(
          'capture real Home level $level $suffix ${light ? 'light' : 'dark'}',
          (tester) async {
            await tester.binding.setSurfaceSize(size);
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final key = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: light ? GameTheme.light : GameTheme.dark,
                home: RepaintBoundary(
                  key: key,
                  child: HomeScreen(
                    level: level,
                    totalLevels: 150,
                    completed: level - 1,
                    crystals: 21,
                    onContinue: () {},
                  ),
                ),
              ),
            );
            await tester.runAsync(() async {
              final context = tester.element(find.byType(HomeScreen));
              await precacheImage(
                AssetImage(ChapterScenes.forLevel(level)!.backgroundAsset),
                context,
              );
              await precacheImage(const AssetImage('doc/logo.png'), context);
            });
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 250));
            expect(tester.takeException(), isNull);
            final output = File(
              'tools/home_scene_preview/screenshots/forest_${level}_${suffix}_${light ? 'light' : 'dark'}.png',
            );
            await tester.runAsync(() async {
              final image =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await output.parent.create(recursive: true);
              await output.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          },
        );
      }
    }
  }
}
