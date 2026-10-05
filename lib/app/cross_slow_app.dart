import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../campaign/campaign_chapter.dart';
import '../campaign/chapter_scene.dart';
import '../campaign/chapter_scene_reveal_screen.dart';
import '../campaign/chapter_transition_screen.dart';
import '../core/theme/game_theme.dart';
import '../core/widgets/pixel_ui.dart';
import '../features/game/data/level_repository.dart';
import '../features/game/game_screen.dart';
import '../features/game/models/level.dart';
import '../features/home/home_screen.dart';
import '../features/menu/menu_screen.dart';
import '../features/splash/splash_screen.dart';
import '../progress/achievements.dart';
import '../progress/campaign_progress.dart';
import '../progress/progress_repository.dart';
import '../progress/theme_repository.dart';

class CrossSlowApp extends StatefulWidget {
  const CrossSlowApp({super.key});

  @override
  State<CrossSlowApp> createState() => _CrossSlowAppState();
}

class _CrossSlowAppState extends State<CrossSlowApp> {
  final repository = ProgressRepository();
  final themeRepository = ThemeRepository();
  late final Future<List<Level>> levels;
  CampaignProgress progress = CampaignProgress();
  Future<void> pendingSave = Future.value();
  final Queue<AchievementDefinition> toastQueue = Queue();
  AchievementDefinition? toast;
  int playingLevelId = 1;
  int? playingEndlessSourceLevelId;
  int playingEndlessRound = 1;
  bool inGame = false;
  bool inEndless = false;
  bool inTransition = false;
  bool transitionBusy = false;
  bool sceneBusy = false;
  bool splashFinished = false;
  ThemeMode themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    levels = _initialize();
  }

  Future<List<Level>> _initialize() async {
    final savedTheme = await themeRepository.load();
    if (mounted) setState(() => themeMode = savedTheme);
    final data = await LevelRepository().load();
    final saved = await repository.load();
    if (mounted) {
      setState(() {
        progress = saved;
        playingLevelId = saved.currentLevel;
        inTransition = saved.pendingChapterId != null;
      });
    }
    return data;
  }

  void _setTheme(ThemeMode mode) {
    setState(() => themeMode = mode);
    themeRepository.save(mode);
  }

  void _save() {
    final snapshot = jsonEncode(progress.toJson());
    pendingSave = pendingSave.then((_) => repository.saveEncoded(snapshot));
  }

  void _checkAchievements(List<Level> data) {
    final newlyUnlocked = AchievementRules.unlockNew(
      progress,
      data,
      DateTime.now(),
    );
    toastQueue.addAll(newlyUnlocked);
    if (toast == null) _showNextToast();
  }

  void _showNextToast() {
    if (!mounted || toastQueue.isEmpty) {
      if (mounted) setState(() => toast = null);
      return;
    }
    setState(() => toast = toastQueue.removeFirst());
    Future<void>.delayed(const Duration(seconds: 3), _showNextToast);
  }

  void _wordFound(List<Level> data, Level level, String word) {
    if (inEndless) {
      if (progress.recordEndlessWord(level, word)) _save();
      return;
    }
    if (!progress.recordWord(level, word)) return;
    _checkAchievements(data);
    _save();
  }

  bool _hintUsed() {
    if (inEndless) {
      if (!progress.recordEndlessHint()) return false;
    } else if (!progress.recordHint(playingLevelId)) {
      return false;
    }
    _save();
    setState(() {});
    return true;
  }

  void _complete(List<Level> data, Level level) {
    if (inEndless) {
      if (!progress.completeEndless(level)) return;
      _save();
      setState(() {});
      return;
    }
    if (!progress.complete(level)) return;
    _checkAchievements(data);
    _save();
    setState(() {});
  }

  void _startEndless(List<Level> data) {
    final sourceId = progress.startEndless(data);
    _save();
    setState(() {
      playingEndlessSourceLevelId = sourceId;
      playingEndlessRound = progress.endlessRound;
      inEndless = true;
      inGame = true;
    });
  }

  void _continueFinal() {
    progress.campaignFinalSeen = true;
    _save();
    setState(() {});
  }

  Future<void> _next(List<Level> data) async {
    await pendingSave;
    if (!mounted) return;
    if (inEndless) {
      _startEndless(data);
      return;
    }
    setState(() {
      inGame = false;
      if (progress.campaignCompleted) return;
      if (progress.pendingChapterId != null) {
        inTransition = true;
      } else if (ChapterScenes.unseenOpeningForLevel(
            progress.currentLevel,
            progress.seenScenes,
          ) !=
          null) {
        // The first visit to a new scene opens its scenery before Home.
      } else {
        playingLevelId = progress.currentLevel;
        inGame = true;
      }
    });
  }

  Future<void> _continueScene(ChapterScene scene) async {
    if (sceneBusy) return;
    setState(() => sceneBusy = true);
    try {
      await pendingSave;
      progress.seenScenes.add(scene.id);
      await repository.save(progress);
      if (!mounted) return;
      setState(() => sceneBusy = false);
    } catch (_) {
      if (mounted) setState(() => sceneBusy = false);
      rethrow;
    }
  }

  Future<void> _continueChapter() async {
    if (transitionBusy) return;
    setState(() => transitionBusy = true);
    try {
      await pendingSave;
      progress.acknowledgeChapter();
      await repository.save(progress);
      if (!mounted) return;
      setState(() {
        transitionBusy = false;
        inTransition = false;
        playingLevelId = progress.currentLevel;
        inGame =
            ChapterScenes.unseenOpeningForLevel(
              progress.currentLevel,
              progress.seenScenes,
            ) ==
            null;
      });
    } catch (_) {
      if (mounted) setState(() => transitionBusy = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'КроссСлов',
    debugShowCheckedModeBanner: false,
    theme: GameTheme.light,
    darkTheme: GameTheme.dark,
    themeMode: themeMode,
    home: !splashFinished
        ? SplashScreen(onFinished: () => setState(() => splashFinished = true))
        : FutureBuilder<List<Level>>(
            future: levels,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Не удалось загрузить уровни: ${snapshot.error}',
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snapshot.data!;
              final index = data.indexWhere(
                (level) =>
                    level.id ==
                    (inEndless ? playingEndlessSourceLevelId : playingLevelId),
              );
              final level = data[index < 0 ? 0 : index];
              Widget screen;
              if (inTransition) {
                final chapter = CampaignChapters.all.firstWhere(
                  (item) => item.id == progress.pendingChapterId,
                );
                screen = ChapterTransitionScreen(
                  chapter: chapter,
                  onContinue: _continueChapter,
                );
              } else if (inGame) {
                screen = GameScreen(
                  key: ValueKey(
                    inEndless
                        ? 'endless-$playingEndlessRound-$playingEndlessSourceLevelId'
                        : 'campaign-$playingLevelId',
                  ),
                  level: level,
                  initialFound: inEndless
                      ? progress.endlessFoundWords
                      : progress.wordsFor(level.id),
                  crystals: progress.crystals,
                  endlessRound: inEndless ? playingEndlessRound : null,
                  sceneOverride: inEndless ? ChapterScenes.forLevel(150) : null,
                  onBack: () => setState(() {
                    inGame = false;
                    inEndless = false;
                  }),
                  onWordFound: (word) => _wordFound(data, level, word),
                  onHintUsed: _hintUsed,
                  onComplete: () => _complete(data, level),
                  onNext: () => _next(data),
                  hasNext: inEndless || level.id < data.length,
                );
              } else if (progress.campaignCompleted &&
                  !progress.campaignFinalSeen) {
                screen = ChapterSceneRevealScreen(
                  key: const ValueKey('campaign-final'),
                  scene: ChapterScenes.forLevel(150)!,
                  title: 'ПУТЕШЕСТВИЕ ЗАВЕРШЕНО',
                  subtitle: 'Пройдено 150 уровней',
                  caption: 'Но слова не заканчиваются...',
                  buttonLabel: 'ПРОДОЛЖИТЬ ИГРАТЬ',
                  onContinue: _continueFinal,
                );
              } else if (ChapterScenes.unseenOpeningForLevel(
                    progress.currentLevel,
                    progress.seenScenes,
                  )
                  case final scene?) {
                screen = ChapterSceneRevealScreen(
                  key: ValueKey('scene-reveal-${scene.id}'),
                  scene: scene,
                  onContinue: () => _continueScene(scene),
                );
              } else {
                screen = HomeScreen(
                  level: progress.currentLevel,
                  totalLevels: data.length,
                  completed: progress.completedLevels,
                  campaignCompleted: progress.campaignCompleted,
                  endlessRoundsCompleted: progress.endlessRoundsCompleted,
                  crystals: progress.crystals,
                  onContinue: () {
                    if (progress.campaignCompleted) {
                      _startEndless(data);
                      return;
                    }
                    setState(() {
                      if (progress.pendingChapterId != null) {
                        inTransition = true;
                      } else if (!progress.campaignCompleted) {
                        playingLevelId = progress.currentLevel;
                        inGame = true;
                      }
                    });
                  },
                  onMenu: (menuContext) => Navigator.of(menuContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MenuScreen(
                        themeMode: themeMode,
                        onThemeChanged: _setTheme,
                        progress: progress,
                        levels: data,
                      ),
                    ),
                  ),
                );
              }
              return Stack(
                children: [
                  screen,
                  if (toast != null)
                    Positioned(
                      top: 38,
                      left: 24,
                      right: 24,
                      child: IgnorePointer(
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: PixelPanel(
                              highlight: true,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('★ ДОСТИЖЕНИЕ ★'),
                                  Text(
                                    toast!.title,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(toast!.description),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
  );
}
