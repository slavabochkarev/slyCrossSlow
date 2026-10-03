import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/game_theme.dart';

enum LetterBoardReaction { correct, wrong, neutral }

class LetterBoard extends StatefulWidget {
  const LetterBoard({
    super.key,
    required this.letters,
    required this.onWord,
    required this.onSelectionChanged,
  });

  final List<String> letters;
  final ValueChanged<String> onWord;
  final ValueChanged<String> onSelectionChanged;

  @override
  State<LetterBoard> createState() => LetterBoardState();
}

class LetterBoardState extends State<LetterBoard>
    with SingleTickerProviderStateMixin {
  late List<int> order;
  late final AnimationController shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  final selected = <int>[];
  List<int> feedbackIds = [];
  LetterBoardReaction? reaction;
  Offset? pointer;
  int reactionToken = 0;

  @override
  void initState() {
    super.initState();
    order = List.generate(widget.letters.length, (index) => index);
  }

  @override
  void didUpdateWidget(covariant LetterBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letters != widget.letters) {
      order = List.generate(widget.letters.length, (index) => index);
      selected.clear();
      feedbackIds = [];
      pointer = null;
    }
  }

  @override
  void dispose() {
    shake.dispose();
    super.dispose();
  }

  void shuffle() {
    if (pointer != null) return;
    setState(() {
      feedbackIds = [];
      order.shuffle();
    });
  }

  void showReaction(LetterBoardReaction value) {
    final token = ++reactionToken;
    setState(() => reaction = value);
    if (value == LetterBoardReaction.wrong) shake.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && reactionToken == token) {
        setState(() {
          feedbackIds = [];
          reaction = null;
        });
      }
    });
  }

  List<Offset> _positions(Size size) {
    final normalized =
        <int, List<Offset>>{
          3: [
            const Offset(.5, .20),
            const Offset(.24, .72),
            const Offset(.76, .72),
          ],
          4: [
            const Offset(.5, .18),
            const Offset(.20, .52),
            const Offset(.80, .52),
            const Offset(.5, .82),
          ],
          5: [
            const Offset(.5, .17),
            const Offset(.20, .43),
            const Offset(.80, .43),
            const Offset(.32, .77),
            const Offset(.68, .77),
          ],
          6: [
            const Offset(.5, .16),
            const Offset(.24, .34),
            const Offset(.76, .34),
            const Offset(.24, .68),
            const Offset(.76, .68),
            const Offset(.5, .82),
          ],
          7: [
            const Offset(.5, .15),
            const Offset(.23, .35),
            const Offset(.77, .35),
            const Offset(.5, .51),
            const Offset(.23, .71),
            const Offset(.77, .71),
            const Offset(.5, .83),
          ],
        }[widget.letters.length] ??
        const [Offset(.5, .5)];
    final diameter = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    return normalized
        .map(
          (point) =>
              center +
              Offset((point.dx - .5) * diameter, (point.dy - .5) * diameter),
        )
        .toList();
  }

  void _track(Offset local, Size size) {
    final positions = _positions(size);
    final radius = math.min(32.0, math.min(size.width, size.height) * .12);
    setState(() {
      pointer = local;
      for (var slot = 0; slot < positions.length; slot++) {
        final id = order[slot];
        if ((positions[slot] - local).distance <= radius + 10 &&
            !selected.contains(id)) {
          selected.add(id);
          widget.onSelectionChanged(
            selected.map((index) => widget.letters[index]).join(),
          );
          break;
        }
      }
    });
  }

  void _end() {
    final word = selected.map((id) => widget.letters[id]).join();
    setState(() {
      feedbackIds = List.of(selected);
      selected.clear();
      pointer = null;
    });
    widget.onSelectionChanged('');
    if (word.isNotEmpty) widget.onWord(word);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final palette = GamePalette.of(context);
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final positions = _positions(size);
      final radius = math.min(32.0, math.min(size.width, size.height) * .12);
      final activeIds = selected.isEmpty ? feedbackIds : selected;
      final trace = activeIds
          .map((id) => positions[order.indexOf(id)])
          .toList();
      final color = reaction == LetterBoardReaction.wrong
          ? const Color(0xFFFF8A93)
          : reaction == LetterBoardReaction.correct
          ? const Color(0xFFADFFDE)
          : palette.accent;
      return AnimatedBuilder(
        animation: shake,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            math.sin(shake.value * math.pi * 6) * (1 - shake.value) * 7,
            0,
          ),
          child: child,
        ),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            reactionToken++;
            feedbackIds = [];
            reaction = null;
            _track(event.localPosition, size);
          },
          onPointerMove: (event) {
            if (pointer != null) _track(event.localPosition, size);
          },
          onPointerUp: (_) => _end(),
          onPointerCancel: (_) => _end(),
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _CircleBoardPainter(palette)),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _TracePainter(trace, pointer, color),
                    ),
                  ),
                ),
              ),
              for (var id = 0; id < order.length; id++)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 330),
                  curve: Curves.easeInOutCubic,
                  left: positions[order.indexOf(id)].dx - radius,
                  top: positions[order.indexOf(id)].dy - radius,
                  width: radius * 2,
                  height: radius * 2,
                  child: IgnorePointer(
                    child: _GlowLetterButton(
                      letter: widget.letters[id],
                      selected: activeIds.contains(id),
                      success: reaction == LetterBoardReaction.correct,
                      palette: palette,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _GlowLetterButton extends StatelessWidget {
  const _GlowLetterButton({
    required this.letter,
    required this.selected,
    required this.success,
    required this.palette,
  });
  final String letter;
  final bool selected;
  final bool success;
  final GamePalette palette;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: selected ? 1.07 : 1,
    duration: const Duration(milliseconds: 110),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [
                  Colors.white,
                  success ? const Color(0xFF86F9CC) : palette.accent,
                ]
              : [Colors.white, palette.cellOpenBottom],
        ),
        border: Border.all(
          color: selected ? Colors.white : const Color(0xFF6C94C2),
          width: 3,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0xDD071331),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: selected
                ? palette.accent
                : palette.outline.withValues(alpha: .4),
            blurRadius: selected ? 15 : 5,
            spreadRadius: selected ? 2 : 0,
          ),
        ],
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: GameColors.midnight,
          fontWeight: FontWeight.w900,
          fontSize: 28,
          height: 1,
        ),
      ),
    ),
  );
}

class _CircleBoardPainter extends CustomPainter {
  const _CircleBoardPainter(this.palette);
  final GamePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = palette.board
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..color = palette.accent.withValues(alpha: .3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleBoardPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class _TracePainter extends CustomPainter {
  const _TracePainter(this.points, this.pointer, this.color);
  final List<Offset> points;
  final Offset? pointer;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (pointer != null) path.lineTo(pointer!.dx, pointer!.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .62)
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .8)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.pointer != pointer ||
      oldDelegate.color != color;
}
