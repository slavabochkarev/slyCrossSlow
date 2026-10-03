import 'package:flutter/material.dart';

import '../core/theme/game_theme.dart';
import '../features/game/data/level_repository.dart';
import '../features/game/models/level.dart';
import '../features/game/game_screen.dart';
import '../features/home/home_screen.dart';
import '../features/splash/splash_screen.dart';
import '../progress/progress_repository.dart';
import '../progress/theme_repository.dart';
import '../features/menu/menu_screen.dart';

class CrossSlowApp extends StatefulWidget {
  const CrossSlowApp({super.key});

  @override
  State<CrossSlowApp> createState() => _CrossSlowAppState();
}

class _CrossSlowAppState extends State<CrossSlowApp> {
  final progress = ProgressRepository();
  final themeRepository = ThemeRepository();
  late final Future<List<Level>> levels;
  final completed = <int>{};
  Future<void> pendingSave = Future.value();
  int currentIndex = 0;
  bool inGame = false;
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
    final loaded = await LevelRepository().load();
    final saved = await progress.load();
    completed.addAll(saved.completed);
    final index = loaded.indexWhere((level) => level.id == saved.currentLevel);
    currentIndex = index < 0 ? 0 : index;
    return loaded;
  }

  void _setTheme(ThemeMode mode) {
    setState(() => themeMode = mode);
    themeRepository.save(mode);
  }

  void _save(List<Level> data) {
    final levelId = data[currentIndex].id;
    final completedIds = {...completed};
    pendingSave = pendingSave.then((_) => progress.save(levelId, completedIds));
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
              if (inGame) {
                return GameScreen(
                  key: ValueKey(currentIndex),
                  level: data[currentIndex],
                  onBack: () => setState(() => inGame = false),
                  onComplete: () {
                    setState(() => completed.add(data[currentIndex].id));
                    _save(data);
                  },
                  onNext: () => setState(() {
                    if (currentIndex < data.length - 1) {
                      currentIndex++;
                    } else {
                      inGame = false;
                    }
                    _save(data);
                  }),
                  hasNext: currentIndex < data.length - 1,
                );
              }
              return HomeScreen(
                level: data[currentIndex].id,
                totalLevels: data.length,
                completed: completed.length,
                onContinue: () => setState(() => inGame = true),
                onMenu: (menuContext) => Navigator.of(menuContext).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MenuScreen(
                      themeMode: themeMode,
                      onThemeChanged: _setTheme,
                      completed: completed.length,
                      totalLevels: data.length,
                      foundWords: data
                          .where((level) => completed.contains(level.id))
                          .fold<int>(
                            0,
                            (sum, level) => sum + level.words.length,
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
  );
}
