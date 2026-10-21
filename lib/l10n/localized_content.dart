import 'package:flutter/widgets.dart';

import '../features/menu/info_content.dart';
import '../progress/achievements.dart';
import 'app_localizations.dart';
import 'app_localizations_ru.dart';

extension LocalizedContext on BuildContext {
  // Also supports isolated widgets and developer labs outside CrossSlowApp.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizationsRu();
}

extension LocalizedContent on AppLocalizations {
  String chapterName(int id) => switch (id) {
    1 => chapterForest,
    2 => chapterLake,
    3 => chapterMountains,
    4 => chapterCastle,
    5 => chapterNorth,
    _ => throw ArgumentError.value(id, 'chapter id'),
  };

  String sceneName(String id) => switch (id) {
    'forest_01' => sceneForest01,
    'forest_02' => sceneForest02,
    'forest_03' => sceneForest03,
    'lake_01' => sceneLake01,
    'lake_02' => sceneLake02,
    'lake_03' => sceneLake03,
    'lake_04' => sceneLake04,
    'mountains_01' => sceneMountains01,
    'mountains_02' => sceneMountains02,
    'mountains_03' => sceneMountains03,
    'mountains_04' => sceneMountains04,
    'castle_01' => sceneCastle01,
    'castle_02' => sceneCastle02,
    'castle_03' => sceneCastle03,
    'castle_04' => sceneCastle04,
    'north_01' => sceneNorth01,
    'north_02' => sceneNorth02,
    'north_03' => sceneNorth03,
    'north_04' => sceneNorth04,
    'north_05' => sceneNorth05,
    _ => throw ArgumentError.value(id, 'scene id'),
  };

  String achievementName(String id) => switch (id) {
    'first_step' => achievementFirstStepTitle,
    'chapter_1' => achievementChapter1Title,
    'chapter_2' => achievementChapter2Title,
    'chapter_3' => achievementChapter3Title,
    'chapter_4' => achievementChapter4Title,
    'chapter_5' => achievementChapter5Title,
    'cross_slow' => achievementCampaignTitle,
    'words_100' => achievementWords100Title,
    'words_500' => achievementWords500Title,
    'words_1000' => achievementWords1000Title,
    'no_hints_10' => achievementNoHints10Title,
    'no_hints_50' => achievementNoHints50Title,
    'large_crossword' => achievementLargeCrosswordTitle,
    _ => throw ArgumentError.value(id, 'achievement id'),
  };

  String achievementDescription(AchievementDefinition achievement) =>
      switch (achievement.metric) {
        AchievementMetric.completed =>
          achievement.id == 'cross_slow'
              ? achievementCampaignDescription(achievement.target)
              : achievementLevelsDescription(achievement.target),
        AchievementMetric.chapter => achievementChapterDescription(
          chapterName(achievement.chapter!.id),
        ),
        AchievementMetric.words => achievementWordsDescription(
          achievement.target,
        ),
        AchievementMetric.withoutHints => achievementNoHintsDescription(
          achievement.target,
        ),
        AchievementMetric.largeCrossword => achievementLargeDescription(15),
      };

  String achievementCategory(AchievementMetric metric) => switch (metric) {
    AchievementMetric.completed ||
    AchievementMetric.chapter => achievementCategoryJourney,
    AchievementMetric.words => achievementCategoryWords,
    AchievementMetric.withoutHints => achievementCategoryWithoutHints,
    AchievementMetric.largeCrossword => achievementCategoryLargeCrosswords,
  };

  /// Stable grouping independent of the text shown in either locale.
  AchievementMetric achievementGroup(AchievementMetric metric) =>
      metric == AchievementMetric.chapter
      ? AchievementMetric.completed
      : metric;

  InfoDocument document(InfoDocument source) {
    if (identical(source, aboutDocument)) {
      return InfoDocument(aboutTitle, [InfoSection('', aboutBody)]);
    }
    if (identical(source, howToDocument)) {
      return InfoDocument(howToTitle, [
        InfoSection(howToConnectTitle, howToConnectBody),
        InfoSection(howToFindTitle, howToFindBody),
        InfoSection(howToHintTitle, howToHintBody),
      ]);
    }
    if (identical(source, feedbackDocument)) {
      return InfoDocument(feedbackTitle, [
        InfoSection('', feedbackBody),
        InfoSection(feedbackDetailsTitle, feedbackDetailsBody),
      ]);
    }
    return InfoDocument(
      identical(source, privacyDocument) ? privacyTitle : termsTitle,
      [
        InfoSection(
          '',
          identical(source, privacyDocument) ? privacyBody : termsBody,
        ),
      ],
      plainText: source.plainText,
    );
  }
}
