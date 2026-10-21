// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get menuTitle => 'MENU';

  @override
  String get gameTab => 'GAME';

  @override
  String get infoTab => 'INFO';

  @override
  String get menuTooltip => 'Menu';

  @override
  String get journeyTitle => 'JOURNEY';

  @override
  String get campaignCompleted => 'Campaign completed';

  @override
  String get playButton => 'PLAY';

  @override
  String get continueButton => 'CONTINUE';

  @override
  String get backHomeTooltip => 'Back to Home';

  @override
  String get endlessTitle => 'ENDLESS GAME';

  @override
  String get shuffleTooltip => 'Shuffle';

  @override
  String get revealLetterTooltip => 'Reveal a letter';

  @override
  String get themeSection => 'THEME';

  @override
  String get darkTheme => 'Dark';

  @override
  String get lightTheme => 'Light';

  @override
  String get crosswordLanguage => 'Crossword language';

  @override
  String get interfaceLanguage => 'Interface language';

  @override
  String get englishUnavailable => 'Available when English levels are added';

  @override
  String get progressSection => 'PROGRESS';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get wordAlreadyFound => 'ALREADY FOUND';

  @override
  String get wordOutsideCrossword => 'VALID WORD, NOT IN THIS PUZZLE';

  @override
  String get tryAgain => 'TRY AGAIN';

  @override
  String get notEnoughCrystals => 'NOT ENOUGH CRYSTALS';

  @override
  String get letterRevealed => 'LETTER REVEALED';

  @override
  String get roundCompletedTitle => '★  ROUND COMPLETE  ★';

  @override
  String get levelCompletedTitle => '★  LEVEL COMPLETE  ★';

  @override
  String get journeyCompletedTitle => '★  JOURNEY COMPLETE  ★';

  @override
  String get allWordsSolved => 'All words solved';

  @override
  String get nextRoundButton => 'NEXT ROUND';

  @override
  String get continuePlayingButton => 'KEEP PLAYING';

  @override
  String get backHomeButton => 'HOME';

  @override
  String get campaignFinalTitle => 'JOURNEY COMPLETE';

  @override
  String get campaignFinalCaption => 'But there are always more words...';

  @override
  String get achievementToastTitle => '★ ACHIEVEMENT ★';

  @override
  String get journeyContinues => 'The journey continues...';

  @override
  String get statsLevelsCompleted => 'Levels completed';

  @override
  String get statsWordsFound => 'Words found';

  @override
  String get statsEndlessRounds => 'Endless rounds';

  @override
  String get statsWithoutHints => 'Levels without hints';

  @override
  String get statsHintsUsed => 'Hints used';

  @override
  String get statsCurrentStreak => 'Current streak';

  @override
  String get statsBestStreak => 'Best streak';

  @override
  String get statsCrystalsEarned => 'Crystals earned';

  @override
  String get appVersionUnavailable => 'КроссСлов · version unavailable';

  @override
  String get dictionaryLicenseTitle => 'Dictionary license';

  @override
  String get dictionaryLicenseMenu => 'English dictionary license';

  @override
  String get licenseLoading => 'Loading license…';

  @override
  String get contactOpenFailed =>
      'Could not open the app. Please copy the contact.';

  @override
  String get contactCopied => 'Contact copied';

  @override
  String get aboutTitle => 'About';

  @override
  String get howToTitle => 'How to play';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get termsTitle => 'EULA';

  @override
  String get feedbackTitle => 'Contact';

  @override
  String get feedbackDetailsTitle => 'What to include';

  @override
  String get aboutBody =>
      'КроссСлов is a journey through a world of words. Connect letters, find words and fill in crosswords. Complete levels and discover new chapters.';

  @override
  String get howToConnectTitle => '1. Connect';

  @override
  String get howToConnectBody =>
      'Drag your finger or mouse from one letter to another. Each letter can be selected once per word.';

  @override
  String get howToFindTitle => '2. Find words';

  @override
  String get howToFindBody =>
      'A correct word appears in the crossword. Find all the words to complete the level.';

  @override
  String get howToHintTitle => '3. Need help?';

  @override
  String get howToHintBody =>
      'Try shuffling the letters for a fresh perspective, or use a hint to reveal one cell.';

  @override
  String get feedbackBody =>
      'Found a bug or have an idea for КроссСлов? Contact the developer by email or Telegram.';

  @override
  String get feedbackDetailsBody =>
      'Describe what happened, which level you were playing and what you expected. You send the message yourself using your chosen app.';

  @override
  String levelLabel(int level) {
    return 'LEVEL $level';
  }

  @override
  String chapterLabel(int number, String name) {
    return 'Chapter $number · $name';
  }

  @override
  String chapterOpeningLabel(int number) {
    return 'CHAPTER $number';
  }

  @override
  String endlessHomeSummary(int count) {
    return 'Endless game · $count';
  }

  @override
  String roundLabel(int round) {
    return 'Round $round';
  }

  @override
  String appVersion(String version) {
    return 'КроссСлов · version $version';
  }

  @override
  String levelsLoadError(String error) {
    return 'Could not load levels: $error';
  }

  @override
  String copyContactTooltip(String contact) {
    return 'Copy $contact';
  }

  @override
  String achievementChapterDescription(String chapter) {
    return 'Complete the $chapter chapter';
  }

  @override
  String achievementLargeDescription(int count) {
    return 'Complete a level with at least $count words';
  }

  @override
  String campaignFinalSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count levels completed',
      one: '$count level completed',
    );
    return '$_temp0';
  }

  @override
  String allLevelsCompleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count levels completed',
      one: 'All $count level completed',
    );
    return '$_temp0';
  }

  @override
  String achievementLevelsDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Complete $count levels',
      one: 'Complete $count level',
    );
    return '$_temp0';
  }

  @override
  String achievementWordsDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Find $count words',
      one: 'Find $count word',
    );
    return '$_temp0';
  }

  @override
  String achievementNoHintsDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Complete $count levels without hints',
      one: 'Complete $count level without hints',
    );
    return '$_temp0';
  }

  @override
  String get chapterForest => 'Forest';

  @override
  String get chapterLake => 'Lake';

  @override
  String get chapterMountains => 'Mountains';

  @override
  String get chapterCastle => 'Castle';

  @override
  String get chapterNorth => 'North';

  @override
  String get sceneForest01 => 'Forest Edge';

  @override
  String get sceneForest02 => 'Deep Forest';

  @override
  String get sceneForest03 => 'Beyond the Forest';

  @override
  String get sceneLake01 => 'Lakeshore';

  @override
  String get sceneLake02 => 'Along the Lake';

  @override
  String get sceneLake03 => 'Waterside Village';

  @override
  String get sceneLake04 => 'Toward the Mountains';

  @override
  String get sceneMountains01 => 'The Ascent Begins';

  @override
  String get sceneMountains02 => 'Highlands';

  @override
  String get sceneMountains03 => 'Mountain Pass';

  @override
  String get sceneMountains04 => 'Road to the Castle';

  @override
  String get sceneCastle01 => 'At the Gates';

  @override
  String get sceneCastle02 => 'Old Courtyard';

  @override
  String get sceneCastle03 => 'High Tower';

  @override
  String get sceneCastle04 => 'Northern Gates';

  @override
  String get sceneNorth01 => 'Northern Valley';

  @override
  String get sceneNorth02 => 'Frozen Expanse';

  @override
  String get sceneNorth03 => 'Northern Lights';

  @override
  String get sceneNorth04 => 'Last Shelter';

  @override
  String get sceneNorth05 => 'World’s Edge';

  @override
  String get achievementFirstStepTitle => 'First Step';

  @override
  String get achievementChapter1Title => 'Trailblazer';

  @override
  String get achievementChapter2Title => 'By the Lake';

  @override
  String get achievementChapter3Title => 'Peak Conqueror';

  @override
  String get achievementChapter4Title => 'Castle Guardian';

  @override
  String get achievementChapter5Title => 'At the Edge of the North';

  @override
  String get achievementCampaignTitle => 'КроссСлов';

  @override
  String get achievementWords100Title => 'Word Collector';

  @override
  String get achievementWords500Title => 'Word Expert';

  @override
  String get achievementWords1000Title => 'Word Scholar';

  @override
  String get achievementNoHints10Title => 'Independent';

  @override
  String get achievementNoHints50Title => 'Master';

  @override
  String get achievementLargeCrosswordTitle => 'Grand Crossword';

  @override
  String get achievementCategoryJourney => 'Journey';

  @override
  String get achievementCategoryWords => 'Words';

  @override
  String get achievementCategoryWithoutHints => 'Without Hints';

  @override
  String get achievementCategoryLargeCrosswords => 'Large Crosswords';

  @override
  String achievementCampaignDescription(int count) {
    return 'Complete all $count levels';
  }

  @override
  String get privacyBody =>
      'КроссСлов does not require registration and does not request your name, telephone number, email address or other personal data to use the game.\n\nGame progress, words found in an unfinished level, crystal balance, statistics, achievements, Endless game state, settings and the selected theme are stored locally on the user\'s device. Cloud synchronization of game data is not used.\n\nThe application does not transmit game progress to the developer and does not use it to identify the user. Local game data can be deleted using the operating system\'s tools by clearing the application\'s data or uninstalling the application from the device.\n\nWhen contacting the developer by email or Telegram, the user voluntarily provides data to the selected communication service. Such data is processed in accordance with the rules of that service.\n\n';

  @override
  String get termsBody =>
      'КроссСлов is a word game. By using the application, the user agrees to the terms of this End User License Agreement.\n\nThe game is provided for personal, non-commercial use. The user may play through the campaign, solve crosswords, use hints, earn achievements and, after completing the campaign, continue playing in Endless mode.\n\nCrystals are exclusively an in-game resource. They may be awarded for actions in the game and spent on functions provided by the game. Crystals are not money, have no monetary value and cannot be exchanged for money.\n\nGame progress and settings are stored locally on the device. The user is responsible for safeguarding the data on their device. Local game data may be lost if the application is uninstalled, its data is cleared, the device is reset or in other circumstances.\n\nThe developer may release updates, fix errors and change the game\'s balance, content, appearance and functionality. Updates may differ from previous versions of the game.\n\nThe application is provided \"as is\". The developer strives to ensure that the game works correctly but does not guarantee the absence of software errors or compatibility with all devices and operating system versions.\n\nThe user must not attempt to interfere with the operation of the application, distribute modified versions of the application on behalf of the developer or use the game\'s materials in violation of applicable law or the rights of rights holders.\n\n';
}
