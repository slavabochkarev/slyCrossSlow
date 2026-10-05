import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Measured inside the real CrosswordBoard allocation, after GameScreen has
/// reserved its header and controls. The 36 px limit is an inspection threshold,
/// never a reason to shrink the LetterBoard or action buttons.
class CrosswordLayoutDiagnostics {
  const CrosswordLayoutDiagnostics({
    required this.rows,
    required this.cols,
    required this.availableArea,
    required this.cellSize,
    required this.renderedSize,
  });

  static const double minimumComfortableCell = 36;

  final int rows;
  final int cols;
  final Size availableArea;
  final double cellSize;
  final Size renderedSize;

  bool get comfortable => cellSize >= minimumComfortableCell;

  String get report =>
      'grid: $cols×$rows | '
      'available crossword area: ${availableArea.width.toStringAsFixed(1)}×${availableArea.height.toStringAsFixed(1)} | '
      'cell size: ${cellSize.toStringAsFixed(1)} | '
      'crossword rendered size: ${renderedSize.width.toStringAsFixed(1)}×${renderedSize.height.toStringAsFixed(1)} | '
      'comfort: ${comfortable ? 'OK' : 'EXCEEDS 36 px minimum'}';
}

CrosswordLayoutDiagnostics measureCrossword({
  required int rows,
  required int cols,
  required Size availableArea,
}) {
  const padding = 12.0;
  final width = math.max(0.0, availableArea.width - padding * 2);
  final height = math.max(0.0, availableArea.height - padding * 2);
  final side = math.max(
    0.0,
    math.min(74.0, math.min(width / cols, height / rows)),
  );
  return CrosswordLayoutDiagnostics(
    rows: rows,
    cols: cols,
    availableArea: availableArea,
    cellSize: side,
    renderedSize: Size(side * cols, side * rows),
  );
}
