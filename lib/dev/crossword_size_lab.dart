import 'package:flutter/material.dart';

import '../core/theme/game_theme.dart';
import '../features/game/game_screen.dart';
import '../features/game/widgets/crossword_layout.dart';
import 'size_lab_levels.dart';

/// Run with: flutter run -t lib/dev/crossword_size_lab.dart
/// This entry point does not load or modify production levels or progress.
void main() => runApp(const CrosswordSizeLab());

class CrosswordSizeLab extends StatefulWidget {
  const CrosswordSizeLab({super.key});

  @override
  State<CrosswordSizeLab> createState() => _CrosswordSizeLabState();
}

class _CrosswordSizeLabState extends State<CrosswordSizeLab> {
  int index = 0;
  String? lastReport;

  void _show(int next) {
    setState(() {
      index = (next + sizeLabLevels.length) % sizeLabLevels.length;
      lastReport = null;
    });
  }

  void _onLayout(CrosswordLayoutDiagnostics layout) {
    final report = '${sizeLabNames[index]} | ${layout.report}';
    if (report != lastReport) {
      lastReport = report;
      debugPrint('[Crossword size lab] $report');
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'КроссСлов · проверка размеров',
    debugShowCheckedModeBanner: false,
    theme: GameTheme.light,
    darkTheme: GameTheme.dark,
    themeMode: ThemeMode.dark,
    home: GameScreen(
      key: ValueKey(index),
      level: sizeLabLevels[index],
      crystals: 0,
      hasNext: true,
      onBack: () => _show(index - 1),
      onComplete: () {},
      onNext: () => _show(index + 1),
      devLabel: '${sizeLabLevels[index].cols}×${sizeLabLevels[index].rows}  ›',
      onDevNext: () => _show(index + 1),
      devPreviewWord: sizeLabNames[index],
      revealCrosswordForSizeLab: true,
      onCrosswordLayout: _onLayout,
    ),
  );
}
