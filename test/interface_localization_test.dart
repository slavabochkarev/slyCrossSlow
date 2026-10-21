import 'package:package_info_plus/package_info_plus.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_slow/app/cross_slow_app.dart';
import 'package:cross_slow/campaign/chapter_scene.dart';
import 'package:cross_slow/campaign/chapter_scene_reveal_screen.dart';
import 'package:cross_slow/campaign/chapter_transition_screen.dart';
import 'package:cross_slow/campaign/campaign_chapter.dart';
import 'package:cross_slow/core/theme/game_theme.dart';
import 'package:cross_slow/features/game/controller/game_controller.dart';
import 'package:cross_slow/features/game/data/game_dictionary.dart';
import 'package:cross_slow/features/game/data/level_repository.dart';
import 'package:cross_slow/features/game/game_screen.dart';
import 'package:cross_slow/features/game/models/level.dart';
import 'package:cross_slow/features/game/widgets/letter_board.dart';
import 'package:cross_slow/features/home/home_screen.dart';
import 'package:cross_slow/features/menu/menu_screen.dart';
import 'package:cross_slow/features/menu/info_content.dart';
import 'package:cross_slow/features/splash/splash_screen.dart';
import 'package:cross_slow/game_language.dart';
import 'package:cross_slow/interface_language.dart';
import 'package:cross_slow/l10n/app_localizations.dart';
import 'package:cross_slow/l10n/app_localizations_en.dart';
import 'package:cross_slow/l10n/app_localizations_ru.dart';
import 'package:cross_slow/l10n/localized_content.dart';
import 'package:cross_slow/progress/achievements.dart';
import 'package:cross_slow/progress/campaign_progress.dart';
import 'package:cross_slow/progress/game_profiles.dart';
import 'package:cross_slow/progress/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Load assets outside widget tests' fake clock before GameScreen caches them.
    await GameDictionary.load(GameLanguage.ru);
    await GameDictionary.load(GameLanguage.en);
    final font = File(
      '${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/arial.ttf',
    );
    if (font.existsSync()) {
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'КроссСлов',
      packageName: 'ru.bochk.crossslov',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('UI defaults to Russian, rejects malformed values and persists independently', () async {
    final prefs = SharedPreferencesAsync();
    final repository = ProgressRepository();
    await repository.saveProfiles(GameProfiles(crystals: 57));
    final before = await prefs.getString(ProgressRepository.profilesKey);
    final settings = InterfaceLanguageController();
    await settings.load();
    expect(settings.language, InterfaceLanguage.ru);
    await prefs.setString('interface_language', 'es');
    await settings.load();
    expect(settings.language, InterfaceLanguage.ru);
    await prefs.setInt('interface_language', 7);
    await settings.load();
    expect(settings.language, InterfaceLanguage.ru);
    await settings.select(InterfaceLanguage.en);
    final restarted = InterfaceLanguageController();
    await restarted.load();
    expect(restarted.language, InterfaceLanguage.en);
    expect(await prefs.getString(ProgressRepository.profilesKey), before);
    expect((await repository.loadProfiles()).crystals, 57);
    settings.dispose();
    restarted.dispose();
  });

  test(
    'ARB key parity, placeholders and Russian/English plurals are complete',
    () {
      final ru = jsonDecode(
        File('lib/l10n/app_ru.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      final en = jsonDecode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      final keys = ru.keys.where((key) => !key.startsWith('@')).toSet();
      expect(en.keys.where((key) => !key.startsWith('@')).toSet(), keys);
      for (final key in keys) {
        expect(en[key], isNotEmpty, reason: key);
        final meta = ru['@$key'] as Map<String, dynamic>;
        for (final parameter
            in (meta['placeholders'] as Map<String, dynamic>? ?? {}).keys) {
          expect(en[key], contains('{$parameter'), reason: key);
        }
      }
      final a = AppLocalizationsRu();
      final b = AppLocalizationsEn();
      expect(a.achievementLevelsDescription(1), 'Пройти 1 уровень');
      expect(a.achievementLevelsDescription(2), 'Пройти 2 уровня');
      expect(a.achievementLevelsDescription(5), 'Пройти 5 уровней');
      expect(b.achievementWordsDescription(1), 'Find 1 word');
      expect(b.achievementWordsDescription(5), 'Find 5 words');
      expect(a.campaignFinalSummary(150), 'Пройдено 150 уровней');
    },
  );

  test('stable IDs localize all scenes, chapters and achievements without changing grouping', () {
    final a = AppLocalizationsRu();
    final b = AppLocalizationsEn();
    for (final scene in ChapterScenes.all) {
      expect(a.sceneName(scene.id), scene.title);
      expect(b.sceneName(scene.id), isNotEmpty);
    }
    for (final chapter in CampaignChapters.all) {
      expect(a.chapterName(chapter.id), chapter.name);
    }
    for (final achievement in AchievementRules.all) {
      expect(a.achievementName(achievement.id), achievement.title);
      expect(a.achievementDescription(achievement), achievement.description);
      expect(b.achievementName(achievement.id), isNotEmpty);
      expect(b.achievementDescription(achievement), isNotEmpty);
      expect(
        a.achievementGroup(achievement.metric),
        b.achievementGroup(achievement.metric),
      );
    }
    expect(
      AchievementRules.all.map((a) => b.achievementGroup(a.metric)).toSet(),
      hasLength(4),
    );
    expect(
      a.document(privacyDocument).sections.single.text,
      privacyDocument.sections.single.text,
    );
    expect(
      a.document(termsDocument).sections.single.text,
      termsDocument.sections.single.text,
    );
    expect(
      b.document(privacyDocument).sections.single.text,
      contains('does not require registration'),
    );
    expect(
      b.document(termsDocument).sections.single.text,
      contains('Crystals are not money'),
    );
  });

  test('feedback behavior is independent of translated strings', () {
    for (final kind in GameFeedback.values) {
      expect(kind.shakes, kind == GameFeedback.tryAgain);
      expect(kind.compact, kind == GameFeedback.outsideCrossword);
      expect(kind.message(AppLocalizationsEn(), 'КОТ'), isNotEmpty);
      expect(kind.message(AppLocalizationsRu(), 'CAT'), isNotEmpty);
    }
    expect(
      GameFeedback.correct.message(AppLocalizationsEn(), 'КОТ'),
      '✦ КОТ ✦',
    );
  });

  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(const CrossSlowApp());
    await tester.runAsync(() async {
      await LevelRepository().load();
      await LevelRepository().load(GameLanguage.en);
      await precacheImage(
        const AssetImage('doc/load.png'),
        tester.element(find.byType(SplashScreen)),
      );
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  }

  Future<void> transition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  for (final crosswordLanguage in GameLanguage.values) {
    testWidgets(
      'real app: both UI locales preserve ${crosswordLanguage.code} profile, controller, hints and restart',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final levels = await tester.runAsync(
          () => LevelRepository().load(crosswordLanguage),
        );
        final level = levels![3];
        final initial = level.words.first.text;
        final state = CampaignProgress(
          currentLevel: 4,
          crystals: 40,
          foundWords: {
            4: {initial},
          },
          seenScenes: ChapterScenes.all.map((s) => s.id).toSet(),
        );
        final profiles = GameProfiles(
          ru: crosswordLanguage == GameLanguage.ru ? state : CampaignProgress(),
          en: crosswordLanguage == GameLanguage.en ? state : CampaignProgress(),
          selectedLanguage: crosswordLanguage,
          crystals: 40,
        );
        await ProgressRepository().saveProfiles(profiles);
        await boot(tester);
        expect(find.text('УРОВЕНЬ 4'), findsOneWidget);
        var home = tester.widget<HomeScreen>(find.byType(HomeScreen));
        home.onMenu!(tester.element(find.byType(HomeScreen)));
        await transition(tester);
        await tester.tap(find.text('Язык интерфейса'));
        await transition(tester);
        await tester.tap(find.text('English'));
        await transition(tester);
        expect(find.text('Interface language'), findsOneWidget);
        final settings = InterfaceLanguageScope.maybeOf(
          tester.element(find.text('Interface language')),
        )!;
        expect(settings.language, InterfaceLanguage.en);
        await tester.pageBack();
        await transition(tester);
        expect(find.text('Crossword language'), findsOneWidget);
        expect(find.text('Interface language'), findsOneWidget);
        await tester.tap(find.text('INFO'));
        await transition(tester);
        await tester.tap(find.text('About'));
        await transition(tester);
        expect(find.textContaining('journey through a world'), findsOneWidget);
        await settings.select(InterfaceLanguage.ru);
        await transition(tester);
        expect(find.text('Об игре'), findsOneWidget);
        expect(
          find.textContaining('путешествии через мир слов'),
          findsOneWidget,
        );
        await settings.select(InterfaceLanguage.en);
        await transition(tester);
        await tester.pageBack();
        await transition(tester);
        await tester.tap(find.text('Privacy Policy'));
        await transition(tester);
        expect(
          find.text('This document is available in Russian only.'),
          findsNothing,
        );
        expect(
          find.textContaining('does not require registration'),
          findsOneWidget,
        );
        await tester.pageBack();
        await transition(tester);
        await tester.pageBack();
        await transition(tester);
        home = tester.widget<HomeScreen>(find.byType(HomeScreen));
        expect(home.language, crosswordLanguage);
        expect(home.crystals, 40);
        expect(find.text('LEVEL 4'), findsOneWidget);
        home.onContinue();
        await transition(tester);
        final dynamic gameState = tester.state(find.byType(GameScreen));
        final controller = gameState.controller as GameController;
        expect(controller.found, contains(initial));
        tester
            .widget<LetterBoard>(find.byType(LetterBoard))
            .onSelectionChanged('ABC');
        await tester.pump();
        await settings.select(InterfaceLanguage.ru);
        await transition(tester);
        expect(
          identical(
            (tester.state(find.byType(GameScreen)) as dynamic).controller,
            controller,
          ),
          isTrue,
        );
        expect(find.text('ABC'), findsOneWidget);
        await tester.tap(find.byTooltip('Открыть букву'));
        await tester.pump();
        expect(
          find.text('БУКВА ОТКРЫТА'),
          findsNothing,
        ); // Current selection takes precedence.
        expect(controller.revealed, hasLength(1));
        await settings.select(InterfaceLanguage.en);
        await tester.pump();
        expect(
          identical(
            (tester.state(find.byType(GameScreen)) as dynamic).controller,
            controller,
          ),
          isTrue,
        );
        expect(controller.found, contains(initial));
        expect(tester.widget<GameScreen>(find.byType(GameScreen)).crystals, 30);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
        final saved = await ProgressRepository().loadProfiles();
        expect(saved.selectedLanguage, crosswordLanguage);
        expect(saved.crystals, 30);
        expect(saved.active.wordsFor(4), contains(initial));
        expect(saved.active.revealedCellsFor(4), controller.revealed);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 2));
        await boot(tester);
        expect(find.text('LEVEL 4'), findsOneWidget);
        home = tester.widget<HomeScreen>(find.byType(HomeScreen));
        expect(home.language, crosswordLanguage);
        expect(home.crystals, 30);
        home.onContinue();
        await transition(tester);
        expect(
          tester.widget<GameScreen>(find.byType(GameScreen)).initialRevealed,
          controller.revealed,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 2));
      },
    );
  }

  testWidgets(
    'English UI crossword selector changes profiles without changing UI language',
    (tester) async {
      await SharedPreferencesAsync().setString('interface_language', 'en');
      final seen = ChapterScenes.all.map((scene) => scene.id).toSet();
      await ProgressRepository().saveProfiles(
        GameProfiles(
          ru: CampaignProgress(currentLevel: 4, seenScenes: {...seen}),
          en: CampaignProgress(currentLevel: 8, seenScenes: {...seen}),
          crystals: 57,
        ),
      );
      await boot(tester);
      Future<void> choose(String label, GameLanguage language) async {
        final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
        home.onMenu!(tester.element(find.byType(HomeScreen)));
        await transition(tester);
        await tester.tap(find.text('Crossword language'));
        await transition(tester);
        expect(find.text('Русский'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.runAsync(() => LevelRepository().load(language));
        await transition(tester);
        expect(
          tester.widget<HomeScreen>(find.byType(HomeScreen)).language,
          language,
        );
        expect(tester.widget<HomeScreen>(find.byType(HomeScreen)).crystals, 57);
      }

      await choose('English', GameLanguage.en);
      expect(find.text('LEVEL 8'), findsOneWidget);
      await choose('Русский', GameLanguage.ru);
      expect(find.text('LEVEL 4'), findsOneWidget);
      expect(
        await SharedPreferencesAsync().getString('interface_language'),
        'en',
      );
      final restored = await ProgressRepository().loadProfiles();
      expect(restored.ru.currentLevel, 4);
      expect(restored.en.currentLevel, 8);
      expect(restored.crystals, 57);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'Endless locale changes keep source, round, controller and wallet',
    (tester) async {
      await ProgressRepository().saveProfiles(
        GameProfiles(
          ru: CampaignProgress(
            currentLevel: 150,
            completed: {for (var i = 1; i <= 150; i++) i},
            campaignFinalSeen: true,
            crystals: 27,
          ),
          crystals: 27,
        ),
      );
      await boot(tester);
      final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
      final settings = InterfaceLanguageScope.maybeOf(
        tester.element(find.byType(HomeScreen)),
      )!;
      home.onContinue();
      await transition(tester);
      final before = tester.widget<GameScreen>(find.byType(GameScreen));
      final dynamic gameState = tester.state(find.byType(GameScreen));
      final controller = gameState.controller;
      await settings.select(InterfaceLanguage.en);
      await transition(tester);
      final after = tester.widget<GameScreen>(find.byType(GameScreen));
      expect(after.level, same(before.level));
      expect(after.endlessRound, 1);
      expect(after.crystals, 27);
      expect(
        (tester.state(find.byType(GameScreen)) as dynamic).controller,
        same(controller),
      );
      expect(find.text('ENDLESS GAME'), findsOneWidget);
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('LEVEL ${after.level.id}'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  Widget harness(
    InterfaceLanguageController settings,
    Widget child, {
    double textScale = 1,
  }) => InterfaceLanguageScope(
    controller: settings,
    child: ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        locale: settings.language.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: GameTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: child,
      ),
    ),
  );

  testWidgets(
    'live feedback translates without resetting the shake or compact state',
    (tester) async {
      final settings = InterfaceLanguageController();
      const level = Level(
        id: 1,
        letters: ['К', 'О', 'Т'],
        words: [WordPlacement(text: 'КОТ', row: 0, col: 0, down: false)],
      );
      await tester.pumpWidget(
        harness(
          settings,
          GameScreen(
            level: level,
            initialFound: const {'КОТ'},
            onBack: () {},
            onComplete: () {},
            onNext: () {},
            hasNext: true,
          ),
        ),
      );
      tester.widget<LetterBoard>(find.byType(LetterBoard)).onWord('КОТ');
      await tester.pump();
      expect(find.text('УЖЕ НАЙДЕНО'), findsOneWidget);
      final dynamic state = tester.state(find.byType(GameScreen));
      final before = state.controller;
      await settings.select(InterfaceLanguage.en);
      await tester.pump();
      expect(find.text('ALREADY FOUND'), findsOneWidget);
      expect(state.controller, same(before));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      settings.dispose();
    },
  );

  testWidgets(
    'invalid and extra words retain feedback animation semantics across locales',
    (tester) async {
      final settings = InterfaceLanguageController();
      const level = Level(
        id: 1,
        letters: ['C', 'A', 'T'],
        words: [WordPlacement(text: 'CAT', row: 0, col: 0, down: false)],
      );
      await tester.pumpWidget(
        harness(
          settings,
          GameScreen(
            level: level,
            language: GameLanguage.en,
            onBack: () {},
            onComplete: () {},
            onNext: () {},
            hasNext: true,
          ),
        ),
      );
      final words = await tester.runAsync(
        () => GameDictionary.load(GameLanguage.en),
      );
      expect(words, contains('ACT'));
      final dynamic state = tester.state(find.byType(GameScreen));
      final controller = state.controller as GameController;
      controller.setDictionary(words!);
      tester.widget<LetterBoard>(find.byType(LetterBoard)).onWord('ACT');
      await tester.pump();
      expect(state.feedback, GameFeedback.outsideCrossword);
      expect(
        find.text(AppLocalizationsRu().wordOutsideCrossword),
        findsOneWidget,
      );
      await settings.select(InterfaceLanguage.en);
      await tester.pump();
      expect(
        find.text(AppLocalizationsEn().wordOutsideCrossword),
        findsOneWidget,
      );
      expect(state.feedback, GameFeedback.outsideCrossword);
      await tester.runAsync(() async {
        tester.widget<LetterBoard>(find.byType(LetterBoard)).onWord('ZZZ');
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      expect(state.feedback, GameFeedback.tryAgain);
      expect(find.text('TRY AGAIN'), findsOneWidget);
      final animation = tester.widget<TweenAnimationBuilder<double>>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TweenAnimationBuilder<double> &&
              widget.key == ValueKey('word-reaction-${state.feedbackSequence}'),
        ),
      );
      expect(animation.tween.begin, 1);
      await settings.select(InterfaceLanguage.ru);
      await tester.pump();
      expect(find.text('ПОПРОБУЙТЕ ЕЩЁ'), findsOneWidget);
      expect(state.controller, same(controller));
      expect(controller.found, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      settings.dispose();
    },
  );

  for (final size in [const Size(360, 800), const Size(1100, 800)]) {
    testWidgets('English layouts at $size with enlarged system text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final settings = InterfaceLanguageController();
      await settings.select(InterfaceLanguage.en);
      final levels = await tester.runAsync(
        () => LevelRepository().load(GameLanguage.en),
      );
      final level = levels![149];
      final imageKey = GlobalKey();
      Future<void> capture(String name) async {
        final directory = Platform.environment['CROSSSLOV_L10N_SCREENSHOTS'];
        if (directory == null) return;
        final boundary =
            imageKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          await Directory(directory).create(recursive: true);
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$directory/${name}_${size.width.toInt()}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> show(Widget child) async {
        await tester.pumpWidget(
          RepaintBoundary(
            key: imageKey,
            child: harness(settings, child, textScale: 1.4),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      }

      await show(
        HomeScreen(
          language: GameLanguage.en,
          level: 150,
          totalLevels: 150,
          completed: 150,
          campaignCompleted: true,
          endlessRoundsCompleted: 1234,
          crystals: 9999,
          onContinue: () {},
        ),
      );
      await capture('home');
      await show(
        ChapterTransitionScreen(
          chapter: CampaignChapters.all[2],
          onContinue: () {},
        ),
      );
      await show(
        ChapterSceneRevealScreen(
          scene: ChapterScenes.all.last,
          onContinue: () {},
        ),
      );
      await show(
        GameScreen(
          level: level,
          language: GameLanguage.en,
          crystals: 9999,
          onBack: () {},
          onComplete: () {},
          onNext: () {},
          hasNext: true,
        ),
      );
      await capture('game');
      final board = tester.widget<LetterBoard>(find.byType(LetterBoard));
      for (final word in level.words) {
        board.onWord(word.text);
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('All words solved'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('victory');
      await show(
        MenuScreen(
          themeMode: ThemeMode.dark,
          onThemeChanged: (_) {},
          progress: CampaignProgress(),
          levels: levels,
          englishAvailable: true,
        ),
      );
      await capture('settings');
      await tester.scrollUntilVisible(
        find.text('Achievements'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();
      expect(find.text('JOURNEY'), findsOneWidget);
      await capture('achievements');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      settings.dispose();
    });
  }
}
