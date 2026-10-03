import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sly_fl_effects_lab/effects/sly_fl_effects.dart';

import '../../core/theme/game_theme.dart';
import '../../core/widgets/pixel_ui.dart';
import '../../core/widgets/scenic_background.dart';
import 'controller/game_controller.dart';
import 'models/level.dart';
import 'widgets/crossword_board.dart';
import 'widgets/letter_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.onBack,
    required this.onComplete,
    required this.onNext,
    required this.hasNext,
  });

  final Level level;
  final VoidCallback onBack;
  final VoidCallback onComplete;
  final VoidCallback onNext;
  final bool hasNext;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller = GameController(widget.level);
  final boardKey = GlobalKey<LetterBoardState>();
  String currentWord = '';
  String feedback = '';
  Color feedbackColor = GameColors.cream;
  int feedbackSequence = 0;
  bool hintPulse = false;
  bool celebrating = false;
  bool showVictory = false;
  bool finishing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _showFeedback(String message, Color color) {
    final sequence = ++feedbackSequence;
    setState(() {
      feedback = message;
      feedbackColor = color;
    });
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted && sequence == feedbackSequence) {
        setState(() => feedback = '');
      }
    });
  }

  void _submit(String word) {
    if (finishing) return;
    final result = controller.submit(word);
    switch (result) {
      case WordResult.correct:
        boardKey.currentState?.showReaction(LetterBoardReaction.correct);
        _showFeedback('✦ $word ✦', GamePalette.of(context).accent);
        if (controller.completed) {
          finishing = true;
          widget.onComplete();
          Future.delayed(const Duration(milliseconds: 480), () {
            if (mounted) setState(() => celebrating = true);
          });
          Future.delayed(const Duration(milliseconds: 760), () {
            if (mounted) setState(() => showVictory = true);
          });
        }
      case WordResult.alreadyFound:
        boardKey.currentState?.showReaction(LetterBoardReaction.neutral);
        _showFeedback('УЖЕ НАЙДЕНО', GameColors.cream);
      case WordResult.unknown:
        boardKey.currentState?.showReaction(LetterBoardReaction.wrong);
        _showFeedback('ПОПРОБУЙ ЕЩЁ', Theme.of(context).colorScheme.error);
    }
  }

  void _hint() {
    if (!controller.revealOne()) return;
    setState(() => hintPulse = true);
    _showFeedback('БУКВА ОТКРЫТА', GameColors.cyan);
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => hintPulse = false);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ScenicBackground(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 28 : 12,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      _header(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: wide
                            ? Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: CrosswordBoard(
                                      controller: controller,
                                      celebrating: celebrating,
                                    ),
                                  ),
                                  const SizedBox(width: 26),
                                  SizedBox(width: 330, child: _controls()),
                                ],
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: CrosswordBoard(
                                      controller: controller,
                                      celebrating: celebrating,
                                    ),
                                  ),
                                  SizedBox(
                                    height: constraints.maxHeight < 640
                                        ? 260
                                        : 330,
                                    child: _controls(),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                if (showVictory) _victoryOverlay(),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _header() => Row(
    children: [
      PixelIconButton(
        icon: Icons.arrow_back,
        label: 'На карту',
        onPressed: widget.onBack,
      ),
      const Spacer(),
      PixelPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          'УРОВЕНЬ ${widget.level.id}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      ),
      const Spacer(),
      const PixelPanel(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.diamond, color: Color(0xFFE990FF), size: 18),
            SizedBox(width: 3),
            Text('0', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    ],
  );

  Widget _controls() => Column(
    children: [
      SizedBox(
        height: 45,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween(begin: .94, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: currentWord.isNotEmpty || feedback.isNotEmpty
                ? TweenAnimationBuilder<double>(
                    key: ValueKey('word-reaction-$feedbackSequence'),
                    tween: Tween(
                      begin: feedback == 'ПОПРОБУЙ ЕЩЁ' ? 1 : 0,
                      end: 0,
                    ),
                    duration: const Duration(milliseconds: 260),
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(
                        math.sin(value * math.pi * 6) * value * 6,
                        0,
                      ),
                      child: child,
                    ),
                    child: PixelPanel(
                      key: ValueKey('$currentWord:$feedback'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      highlight: feedback.startsWith('✦'),
                      child: Text(
                        currentWord.isNotEmpty ? currentWord : feedback,
                        style: TextStyle(
                          fontSize: 23,
                          color: currentWord.isNotEmpty
                              ? GamePalette.of(context).accent
                              : feedbackColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
      Expanded(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270, maxHeight: 270),
            child: AspectRatio(
              aspectRatio: 1,
              child: LetterBoard(
                key: boardKey,
                letters: widget.level.letters,
                onWord: _submit,
                onSelectionChanged: (word) =>
                    setState(() => currentWord = word),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 7),
      Row(
        children: [
          Expanded(
            child: PixelButton(
              onPressed: () => boardKey.currentState?.shuffle(),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shuffle, size: 20),
                  SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'ПЕРЕМЕШАТЬ',
                      maxLines: 1,
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedScale(
            scale: hintPulse ? 1.14 : 1,
            duration: const Duration(milliseconds: 150),
            child: PixelButton(
              onPressed: _hint,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb, color: GameColors.orange, size: 20),
                  SizedBox(width: 4),
                  Text('10 💎', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _victoryOverlay() => Positioned.fill(
    child: Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: GameColors.midnight.withValues(alpha: .78)),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: EffectPlayer(
              key: ValueKey('confetti-${widget.level.id}'),
              config: const ConfettiConfig(
                particleCount: 76,
                particleWidth: 7,
                particleHeight: 12,
                startDelay: Duration(milliseconds: 80),
                emissionDuration: Duration(milliseconds: 330),
                duration: Duration(milliseconds: 1500),
                flipEnabled: true,
              ),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: PixelPanel(
                highlight: true,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '★  УРОВЕНЬ ПРОЙДЕН  ★',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        color: GameColors.orange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Все слова разгаданы',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      '+3 💎',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: GameColors.cyan,
                      ),
                    ),
                    const SizedBox(height: 19),
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: PixelButton(
                        onPressed: widget.onNext,
                        accent: true,
                        child: Text(
                          widget.hasNext ? 'ДАЛЬШЕ' : 'НА КАРТУ',
                          style: const TextStyle(
                            fontSize: 17,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
