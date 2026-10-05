import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sly_fl_effects_lab/effects/sly_fl_effects.dart';

import '../../campaign/chapter_scene.dart';
import '../../campaign/chapter_scene_backdrop.dart';
import '../../core/theme/game_theme.dart';
import '../../core/widgets/pixel_ui.dart';
import '../../core/widgets/scenic_background.dart';
import 'controller/game_controller.dart';
import 'data/game_dictionary.dart';
import 'models/level.dart';
import 'widgets/crossword_board.dart';
import 'widgets/crossword_layout.dart';
import 'widgets/letter_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.onBack,
    required this.onComplete,
    required this.onNext,
    required this.hasNext,
    this.initialFound = const {},
    this.onWordFound,
    this.onHintUsed,
    this.crystals = 0,
    this.devLabel,
    this.onDevNext,
    this.devPreviewWord,
    this.revealCrosswordForSizeLab = false,
    this.onCrosswordLayout,
    this.endlessRound,
    this.sceneOverride,
  });

  final Level level;
  final VoidCallback onBack;
  final VoidCallback onComplete;
  final VoidCallback onNext;
  final bool hasNext;
  final Set<String> initialFound;
  final ValueChanged<String>? onWordFound;
  final bool Function()? onHintUsed;
  final int crystals;
  final String? devLabel;
  final VoidCallback? onDevNext;
  final String? devPreviewWord;
  final bool revealCrosswordForSizeLab;
  final ValueChanged<CrosswordLayoutDiagnostics>? onCrosswordLayout;
  final int? endlessRound;
  final ChapterScene? sceneOverride;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller = GameController(
    widget.level,
    initialFound: widget.initialFound,
  );
  late final Future<Set<String>> dictionary;
  final boardKey = GlobalKey<LetterBoardState>();
  String currentWord = '';
  String feedback = '';
  Color feedbackColor = GameColors.cream;
  int feedbackSequence = 0;
  int submissionSequence = 0;
  bool hintPulse = false;
  bool celebrating = false;
  bool showVictory = false;
  bool finishing = false;
  bool advancing = false;

  @override
  void initState() {
    super.initState();
    currentWord = widget.devPreviewWord ?? '';
    dictionary = GameDictionary.load();
  }

  void _advance() {
    if (advancing) return;
    advancing = true;
    widget.onNext();
  }

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

  void _submit(String word) async {
    if (finishing) return;
    final sequence = ++submissionSequence;
    var result = controller.submit(word);
    if (result == WordResult.unknown) {
      final words = await dictionary;
      if (!mounted || finishing || sequence != submissionSequence) return;
      controller.setDictionary(words);
      result = controller.submit(word);
    }
    switch (result) {
      case WordResult.correct:
        widget.onWordFound?.call(GameDictionary.normalize(word));
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
      case WordResult.validNotInCrossword:
        boardKey.currentState?.showReaction(LetterBoardReaction.neutral);
        _showFeedback('СЛОВО ЕСТЬ! НО НЕ В ЭТОМ КРОССВОРДЕ', GameColors.cyan);
      case WordResult.unknown:
        boardKey.currentState?.showReaction(LetterBoardReaction.wrong);
        _showFeedback('ПОПРОБУЙТЕ ЕЩЁ', Theme.of(context).colorScheme.error);
    }
  }

  void _hint() {
    if (finishing || !controller.canRevealOne) return;
    if (widget.onHintUsed != null && !widget.onHintUsed!()) {
      _showFeedback('НЕДОСТАТОЧНО КРИСТАЛЛОВ', GameColors.orange);
      return;
    }
    if (!controller.revealOne()) return;
    setState(() => hintPulse = true);
    _showFeedback('БУКВА ОТКРЫТА', GameColors.cyan);
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => hintPulse = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scene =
        widget.sceneOverride ?? ChapterScenes.forLevel(widget.level.id);
    final gameUi = SafeArea(
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
                                    revealAllForSizeLab:
                                        widget.revealCrosswordForSizeLab,
                                    onLayout: widget.onCrosswordLayout,
                                  ),
                                ),
                                const SizedBox(width: 26),
                                SizedBox(
                                  width: 330,
                                  child: _readableControls(scene != null),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: CrosswordBoard(
                                    controller: controller,
                                    celebrating: celebrating,
                                    revealAllForSizeLab:
                                        widget.revealCrosswordForSizeLab,
                                    onLayout: widget.onCrosswordLayout,
                                  ),
                                ),
                                SizedBox(
                                  height: constraints.maxHeight < 640
                                      ? 260
                                      : 330,
                                  child: _readableControls(scene != null),
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
    );
    return Scaffold(
      body: scene == null
          ? ScenicBackground(child: gameUi)
          : ChapterSceneBackdrop(
              scene: scene,
              ambientEffects: false,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0x5007142A)),
                  gameUi,
                ],
              ),
            ),
    );
  }

  Widget _readableControls(bool hasScene) => hasScene
      ? DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              radius: .86,
              colors: [Color(0x7007152B), Color(0x0007152B)],
            ),
          ),
          child: _controls(),
        )
      : _controls();

  Widget _header() => Row(
    children: [
      PixelIconButton(
        icon: Icons.arrow_back,
        label: widget.devLabel == null ? 'На главную' : 'Предыдущая сетка',
        onPressed: widget.onBack,
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Tooltip(
              message: widget.onDevNext == null
                  ? ''
                  : 'Следующая тестовая сетка',
              child: GestureDetector(
                onTap: widget.onDevNext,
                child: PixelPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: widget.endlessRound == null
                        ? Text(
                            widget.devLabel ?? 'УРОВЕНЬ ${widget.level.id}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'БЕСКОНЕЧНАЯ ИГРА',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Раунд ${widget.endlessRound}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      PixelPanel(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          children: [
            const CrystalIcon(size: 18),
            const SizedBox(width: 3),
            Text(
              '${widget.crystals}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _controls() => LayoutBuilder(
    builder: (context, constraints) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
                        begin: feedback == 'ПОПРОБУЙТЕ ЕЩЁ' ? 1 : 0,
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
                            fontSize: feedback.startsWith('СЛОВО ЕСТЬ!')
                                ? 13
                                : 23,
                            color: currentWord.isNotEmpty
                                ? GamePalette.of(context).accent
                                : feedbackColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: feedback.startsWith('СЛОВО ЕСТЬ!')
                                ? .2
                                : 2,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        SizedBox(
          height: math.min(285, constraints.maxHeight - 45),
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 270,
                    maxHeight: 270,
                  ),
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
              Positioned(
                left: 0,
                bottom: 12,
                width: 48,
                height: 44,
                child: Tooltip(
                  message: 'Перемешать',
                  child: PixelButton(
                    onPressed: () => boardKey.currentState?.shuffle(),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.shuffle, size: 22),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 12,
                width: 48,
                height: 44,
                child: AnimatedScale(
                  scale: hintPulse ? 1.14 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Tooltip(
                    message: 'Открыть букву',
                    child: PixelButton(
                      onPressed: _hint,
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.lightbulb,
                        color: GameColors.orange,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _victoryOverlay() => Positioned.fill(
    child: Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: GameColors.midnight.withValues(alpha: .78)),
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
                    Text(
                      widget.endlessRound != null
                          ? '★  РАУНД ЗАВЕРШЁН  ★'
                          : widget.hasNext
                          ? '★  УРОВЕНЬ ПРОЙДЕН  ★'
                          : '★  ПУТЕШЕСТВИЕ ЗАВЕРШЕНО  ★',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        color: GameColors.orange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.endlessRound != null
                          ? 'Все слова разгаданы'
                          : widget.hasNext
                          ? 'Все слова разгаданы'
                          : 'Все 150 уровней пройдены',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 9),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '+3',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: GameColors.cyan,
                          ),
                        ),
                        SizedBox(width: 5),
                        CrystalIcon(size: 28),
                      ],
                    ),
                    const SizedBox(height: 19),
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: PixelButton(
                        onPressed: _advance,
                        accent: true,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.endlessRound != null
                                ? 'СЛЕДУЮЩИЙ РАУНД'
                                : widget.hasNext
                                ? 'ПРОДОЛЖИТЬ ИГРАТЬ'
                                : 'НА ГЛАВНУЮ',
                            style: const TextStyle(
                              fontSize: 17,
                              letterSpacing: 1,
                            ),
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
      ],
    ),
  );
}
