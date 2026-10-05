import 'package:flutter/material.dart';

import '../core/theme/game_theme.dart';
import '../features/game/game_screen.dart';
import '../features/game/widgets/crossword_layout.dart';
import 'play_lab_levels.dart';

/// Run with: flutter run -t lib/dev/crossword_play_lab.dart
/// Uses only in-memory state and never loads production levels or progress.
void main() => runApp(const CrosswordPlayLab());

class CrosswordPlayLab extends StatefulWidget {
  const CrosswordPlayLab({super.key});

  @override
  State<CrosswordPlayLab> createState() => _CrosswordPlayLabState();
}

class _CrosswordPlayLabState extends State<CrosswordPlayLab> {
  int index = 0;
  String? lastReport;

  void _show(int next) {
    setState(() {
      index = (next + playLabLevels.length) % playLabLevels.length;
      lastReport = null;
    });
  }

  void _onLayout(CrosswordLayoutDiagnostics layout) {
    final level = playLabLevels[index];
    final report =
        '${level.words.length} слов · ${level.cols}×${level.rows} | '
        'crossword area ${layout.availableArea.width.toStringAsFixed(1)}×${layout.availableArea.height.toStringAsFixed(1)} | '
        'cell ${layout.cellSize.toStringAsFixed(1)} px';
    if (report != lastReport) {
      lastReport = report;
      debugPrint('[Crossword Play Lab] $report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = playLabLevels[index];
    return MaterialApp(
      title: 'КроссСлов · Play Lab',
      debugShowCheckedModeBanner: false,
      theme: GameTheme.light,
      darkTheme: GameTheme.dark,
      themeMode: ThemeMode.dark,
      home: GameScreen(
        key: ValueKey(index),
        level: level,
        crystals: 0,
        hasNext: true,
        onBack: () => _show(index - 1),
        onComplete: () {},
        onNext: () => _show(index + 1),
        devLabel: '${level.words.length} слов · ${level.cols}×${level.rows}  ›',
        onDevNext: () => _show(index + 1),
        onCrosswordLayout: _onLayout,
      ),
    );
  }
}
