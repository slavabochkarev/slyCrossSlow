import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/pixel_ui.dart';
import '../controller/game_controller.dart';

class CrosswordBoard extends StatefulWidget {
  const CrosswordBoard({
    super.key,
    required this.controller,
    this.celebrating = false,
  });

  final GameController controller;
  final bool celebrating;

  @override
  State<CrosswordBoard> createState() => _CrosswordBoardState();
}

class _CrosswordBoardState extends State<CrosswordBoard> {
  final visible = <String>{};
  final glowing = <String>{};
  final processedWords = <String>{};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    _onChange();
  }

  @override
  void didUpdateWidget(covariant CrosswordBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChange);
      visible.clear();
      glowing.clear();
      processedWords.clear();
      widget.controller.addListener(_onChange);
      _onChange();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _reveal(String key) {
    if (!mounted) return;
    setState(() {
      visible.add(key);
      glowing.add(key);
    });
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => glowing.remove(key));
    });
  }

  void _onChange() {
    for (final key in widget.controller.revealed) {
      if (!visible.contains(key)) _reveal(key);
    }
    for (final word in widget.controller.level.words) {
      if (!widget.controller.found.contains(word.text) ||
          !processedWords.add(word.text)) {
        continue;
      }
      for (var i = 0; i < word.text.length; i++) {
        final key =
            '${word.row + (word.down ? i : 0)}:${word.col + (word.down ? 0 : i)}';
        if (!visible.contains(key)) {
          Future.delayed(
            Duration(milliseconds: 130 + i * 75),
            () => _reveal(key),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final level = widget.controller.level;
      final side = math.min(
        74.0,
        math.min(
          (constraints.maxWidth - 28) / level.cols,
          (constraints.maxHeight - 28) / level.rows,
        ),
      );
      final cells = <String, String>{};
      for (final word in level.words) {
        for (var i = 0; i < word.text.length; i++) {
          cells['${word.row + (word.down ? i : 0)}:${word.col + (word.down ? 0 : i)}'] =
              word.text[i];
        }
      }
      return Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0x99051130), Color(0x00051130)],
              radius: .82,
            ),
          ),
          child: SizedBox(
            width: side * level.cols,
            height: side * level.rows,
            child: Stack(
              children: [
                for (var row = 0; row < level.rows; row++)
                  for (var col = 0; col < level.cols; col++)
                    if (cells.containsKey('$row:$col'))
                      Positioned(
                        left: col * side + 2,
                        top: row * side + 2,
                        width: side - 4,
                        height: side - 4,
                        child: PixelCell(
                          letter: cells['$row:$col']!,
                          open: visible.contains('$row:$col'),
                          side: side,
                          glowing:
                              glowing.contains('$row:$col') ||
                              widget.celebrating,
                        ),
                      ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
