import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cross_slow/app/cross_slow_app.dart';
import 'package:cross_slow/campaign/chapter_scene.dart';
import 'package:cross_slow/features/game/data/level_repository.dart';
import 'package:cross_slow/features/home/home_screen.dart';
import 'package:cross_slow/features/menu/menu_screen.dart';
import 'package:cross_slow/features/splash/splash_screen.dart';
import 'package:cross_slow/game_language.dart';
import 'package:cross_slow/interface_language.dart';
import 'package:cross_slow/l10n/app_localizations.dart';
import 'package:cross_slow/l10n/localized_content.dart';
import 'package:cross_slow/progress/campaign_progress.dart';
import 'package:cross_slow/progress/game_profiles.dart';
import 'package:cross_slow/progress/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LevelRepository().load();
    await LevelRepository().load(GameLanguage.en);
  });
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    PackageInfo.setMockInitialValues(
      appName: 'КроссСлов',
      packageName: 'ru.bochk.crossslov',
      version: '1.1.2',
      buildNumber: '2',
      buildSignature: '',
    );
  });
  GameProfiles sample() => GameProfiles(
    ru: CampaignProgress(
      currentLevel: 11,
      completed: {for (var i = 1; i <= 10; i++) i},
      wordsFound: 123,
      hintsUsed: 9,
      levelsWithoutHints: 7,
      currentStreak: 5,
      bestStreak: 8,
      crystalsEarned: 39,
      endlessRoundsCompleted: 3,
      unlockedAt: {'words_100': DateTime.utc(2026, 10, 12)},
      seenScenes: ChapterScenes.all.map((s) => s.id).toSet(),
    ),
    en: CampaignProgress(
      currentLevel: 3,
      completed: {1, 2},
      wordsFound: 12,
      hintsUsed: 1,
      levelsWithoutHints: 1,
      currentStreak: 1,
      bestStreak: 2,
      crystalsEarned: 6,
      endlessRoundsCompleted: 0,
      seenScenes: ChapterScenes.all.map((s) => s.id).toSet(),
    ),
    crystals: 57,
  );
  test('legacy Russian statistics migrate once with the original balance and empty English profile', () async {
    final original = sample().ru;
    original.crystals = 57;
    final preferences = SharedPreferencesAsync();
    final old = jsonEncode(original.toJson());
    await preferences.setString(ProgressRepository.stateKey, old);
    final repository = ProgressRepository();
    final migrated = await repository.loadProfiles();
    expect(migrated.ru.toJson(), original.toJson());
    expect(migrated.en.completedLevels, 0);
    expect(migrated.en.wordsFound, 0);
    expect(migrated.en.unlockedAt, isEmpty);
    expect(migrated.crystals, 57);
    final snapshot = await preferences.getString(
      ProgressRepository.profilesKey,
    );
    await repository.loadProfiles();
    expect(
      await preferences.getString(ProgressRepository.profilesKey),
      snapshot,
    );
    expect(await preferences.getString(ProgressRepository.stateKey), old);
  });

  Future<void> frames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

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

  Future<void> menu(WidgetTester tester) async {
    final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    home.onMenu!(tester.element(find.byType(HomeScreen)));
    await frames(tester);
  }

  Future<void> change(WidgetTester tester, GameLanguage language) async {
    await menu(tester);
    final l10n = tester.element(find.byType(MenuScreen)).l10n;
    await tester.tap(find.text(l10n.crosswordLanguage));
    await frames(tester);
    await tester.tap(find.text(language.label));
    await tester.runAsync(() => LevelRepository().load(language));
    await frames(tester);
  }

  Future<void> statistics(WidgetTester tester, GameLanguage language) async {
    await menu(tester);
    final screen = tester.widget<MenuScreen>(find.byType(MenuScreen));
    expect(screen.language, language);
    final isRu = language == GameLanguage.ru;
    expect(screen.progress.completedLevels, isRu ? 10 : 2);
    expect(screen.progress.crystals, 57);
    final l10n = tester.element(find.byType(MenuScreen)).l10n;
    await tester.ensureVisible(find.text(l10n.statisticsTitle));
    await tester.tap(find.text(l10n.statisticsTitle));
    await frames(tester);
    expect(find.text(isRu ? '10 / 150' : '2 / 150'), findsOneWidget);
    expect(find.text(isRu ? '123' : '12'), findsOneWidget);
    expect(find.text(isRu ? '39' : '6'), findsOneWidget);
    final settings = InterfaceLanguageScope.maybeOf(
      tester.element(find.text(l10n.statisticsTitle)),
    )!;
    await settings.select(
      settings.language == InterfaceLanguage.ru
          ? InterfaceLanguage.en
          : InterfaceLanguage.ru,
    );
    await frames(tester);
    expect(find.text(isRu ? '10 / 150' : '2 / 150'), findsOneWidget);
    expect(find.text(isRu ? '123' : '12'), findsOneWidget);
    await tester.tap(find.byType(BackButton).last);
    await frames(tester);
    final localized = tester.element(find.byType(MenuScreen)).l10n;
    await tester.scrollUntilVisible(
      find.text(localized.achievementsTitle),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text(localized.achievementsTitle));
    await frames(tester);
    final wordTitle = localized.achievementName('words_100');
    await tester.scrollUntilVisible(
      find.text(wordTitle),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text(wordTitle), matching: find.byType(ListTile)),
    );
    expect(tile.trailing, isRu ? isNotNull : isNull);
    expect(
      (tile.subtitle! as Text).data,
      isRu ? localized.achievementWordsDescription(100) : contains('12 / 100'),
    );
    await tester.tap(find.byType(BackButton).last);
    await frames(tester);
    await tester.tap(find.byType(BackButton).last);
    await frames(tester);
  }

  testWidgets(
    'actual statistics and achievements stay distinct RU 10 / EN 2 through UI locales and restart',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await ProgressRepository().saveProfiles(sample());
      await boot(tester);
      await statistics(tester, GameLanguage.ru);
      await change(tester, GameLanguage.en);
      await statistics(tester, GameLanguage.en);
      await change(tester, GameLanguage.ru);
      await statistics(tester, GameLanguage.ru);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      await boot(tester);
      await statistics(tester, GameLanguage.ru);
      await change(tester, GameLanguage.en);
      await statistics(tester, GameLanguage.en);
      final saved = await ProgressRepository().loadProfiles();
      expect(saved.ru.completedLevels, 10);
      expect(saved.en.completedLevels, 2);
      expect(saved.ru.hintsUsed, 9);
      expect(saved.en.hintsUsed, 1);
      expect(saved.ru.levelsWithoutHints, 7);
      expect(saved.en.levelsWithoutHints, 1);
      expect(saved.ru.currentStreak, 5);
      expect(saved.en.currentStreak, 1);
      expect(saved.ru.bestStreak, 8);
      expect(saved.en.bestStreak, 2);
      expect(saved.ru.endlessRoundsCompleted, 3);
      expect(saved.en.endlessRoundsCompleted, 0);
      expect(saved.crystals, 57);
      expect(saved.en.unlockedAt, isEmpty);
      expect(saved.ru.unlockedAt.keys, contains('words_100'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  for (final achievements in [false, true]) {
    testWidgets(
      'open ${achievements ? 'achievements' : 'statistics'} follows updated profile',
      (tester) async {
        final profiles = sample();
        var selected = GameLanguage.ru;
        late StateSetter update;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MaterialApp(
                locale: const Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: MenuScreen(
                  themeMode: ThemeMode.dark,
                  onThemeChanged: (_) {},
                  progress: profiles.profile(selected),
                  language: selected,
                  levels: const [],
                  englishAvailable: true,
                ),
              );
            },
          ),
        );
        await frames(tester);
        final title = achievements ? 'Achievements' : 'Statistics';
        await tester.scrollUntilVisible(
          find.text(title),
          150,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.text(title));
        await frames(tester);
        if (achievements) {
          await tester.scrollUntilVisible(
            find.text('Word Collector'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          final tile = tester.widget<ListTile>(
            find.ancestor(
              of: find.text('Word Collector'),
              matching: find.byType(ListTile),
            ),
          );
          expect(tile.trailing, isNotNull);
        } else {
          expect(find.text('10 / 0'), findsOneWidget);
        }
        update(() => selected = GameLanguage.en);
        await frames(tester);
        expect(
          tester
              .widget<MenuScreen>(find.byType(MenuScreen, skipOffstage: false))
              .progress,
          same(profiles.en),
        );
        if (achievements) {
          final tile = tester.widget<ListTile>(
            find.ancestor(
              of: find.text('Word Collector'),
              matching: find.byType(ListTile),
            ),
          );
          expect(tile.trailing, isNull);
          expect((tile.subtitle! as Text).data, contains('12 / 100'));
        } else {
          expect(find.text('2 / 0'), findsOneWidget);
          expect(find.text('12'), findsOneWidget);
        }
      },
    );
  }
}
