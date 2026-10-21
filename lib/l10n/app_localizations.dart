import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// menuTitle
  ///
  /// In ru, this message translates to:
  /// **'МЕНЮ'**
  String get menuTitle;

  /// gameTab
  ///
  /// In ru, this message translates to:
  /// **'ИГРА'**
  String get gameTab;

  /// infoTab
  ///
  /// In ru, this message translates to:
  /// **'ИНФО'**
  String get infoTab;

  /// menuTooltip
  ///
  /// In ru, this message translates to:
  /// **'Меню'**
  String get menuTooltip;

  /// journeyTitle
  ///
  /// In ru, this message translates to:
  /// **'ПУТЕШЕСТВИЕ'**
  String get journeyTitle;

  /// campaignCompleted
  ///
  /// In ru, this message translates to:
  /// **'Кампания пройдена'**
  String get campaignCompleted;

  /// playButton
  ///
  /// In ru, this message translates to:
  /// **'ИГРАТЬ'**
  String get playButton;

  /// continueButton
  ///
  /// In ru, this message translates to:
  /// **'ПРОДОЛЖИТЬ'**
  String get continueButton;

  /// backHomeTooltip
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get backHomeTooltip;

  /// endlessTitle
  ///
  /// In ru, this message translates to:
  /// **'БЕСКОНЕЧНАЯ ИГРА'**
  String get endlessTitle;

  /// shuffleTooltip
  ///
  /// In ru, this message translates to:
  /// **'Перемешать'**
  String get shuffleTooltip;

  /// revealLetterTooltip
  ///
  /// In ru, this message translates to:
  /// **'Открыть букву'**
  String get revealLetterTooltip;

  /// themeSection
  ///
  /// In ru, this message translates to:
  /// **'ТЕМА'**
  String get themeSection;

  /// darkTheme
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get darkTheme;

  /// lightTheme
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get lightTheme;

  /// crosswordLanguage
  ///
  /// In ru, this message translates to:
  /// **'Язык кроссвордов'**
  String get crosswordLanguage;

  /// interfaceLanguage
  ///
  /// In ru, this message translates to:
  /// **'Язык интерфейса'**
  String get interfaceLanguage;

  /// englishUnavailable
  ///
  /// In ru, this message translates to:
  /// **'Доступен после добавления английских уровней'**
  String get englishUnavailable;

  /// progressSection
  ///
  /// In ru, this message translates to:
  /// **'ПРОГРЕСС'**
  String get progressSection;

  /// statisticsTitle
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get statisticsTitle;

  /// achievementsTitle
  ///
  /// In ru, this message translates to:
  /// **'Достижения'**
  String get achievementsTitle;

  /// wordAlreadyFound
  ///
  /// In ru, this message translates to:
  /// **'УЖЕ НАЙДЕНО'**
  String get wordAlreadyFound;

  /// wordOutsideCrossword
  ///
  /// In ru, this message translates to:
  /// **'СЛОВО ЕСТЬ! НО НЕ В ЭТОМ КРОССВОРДЕ'**
  String get wordOutsideCrossword;

  /// tryAgain
  ///
  /// In ru, this message translates to:
  /// **'ПОПРОБУЙТЕ ЕЩЁ'**
  String get tryAgain;

  /// notEnoughCrystals
  ///
  /// In ru, this message translates to:
  /// **'НЕДОСТАТОЧНО КРИСТАЛЛОВ'**
  String get notEnoughCrystals;

  /// letterRevealed
  ///
  /// In ru, this message translates to:
  /// **'БУКВА ОТКРЫТА'**
  String get letterRevealed;

  /// roundCompletedTitle
  ///
  /// In ru, this message translates to:
  /// **'★  РАУНД ЗАВЕРШЁН  ★'**
  String get roundCompletedTitle;

  /// levelCompletedTitle
  ///
  /// In ru, this message translates to:
  /// **'★  УРОВЕНЬ ПРОЙДЕН  ★'**
  String get levelCompletedTitle;

  /// journeyCompletedTitle
  ///
  /// In ru, this message translates to:
  /// **'★  ПУТЕШЕСТВИЕ ЗАВЕРШЕНО  ★'**
  String get journeyCompletedTitle;

  /// allWordsSolved
  ///
  /// In ru, this message translates to:
  /// **'Все слова разгаданы'**
  String get allWordsSolved;

  /// nextRoundButton
  ///
  /// In ru, this message translates to:
  /// **'СЛЕДУЮЩИЙ РАУНД'**
  String get nextRoundButton;

  /// continuePlayingButton
  ///
  /// In ru, this message translates to:
  /// **'ПРОДОЛЖИТЬ ИГРАТЬ'**
  String get continuePlayingButton;

  /// backHomeButton
  ///
  /// In ru, this message translates to:
  /// **'НА ГЛАВНУЮ'**
  String get backHomeButton;

  /// campaignFinalTitle
  ///
  /// In ru, this message translates to:
  /// **'ПУТЕШЕСТВИЕ ЗАВЕРШЕНО'**
  String get campaignFinalTitle;

  /// campaignFinalCaption
  ///
  /// In ru, this message translates to:
  /// **'Но слова не заканчиваются...'**
  String get campaignFinalCaption;

  /// achievementToastTitle
  ///
  /// In ru, this message translates to:
  /// **'★ ДОСТИЖЕНИЕ ★'**
  String get achievementToastTitle;

  /// journeyContinues
  ///
  /// In ru, this message translates to:
  /// **'Путь продолжается...'**
  String get journeyContinues;

  /// statsLevelsCompleted
  ///
  /// In ru, this message translates to:
  /// **'Пройдено уровней'**
  String get statsLevelsCompleted;

  /// statsWordsFound
  ///
  /// In ru, this message translates to:
  /// **'Найдено слов'**
  String get statsWordsFound;

  /// statsEndlessRounds
  ///
  /// In ru, this message translates to:
  /// **'Бесконечные раунды'**
  String get statsEndlessRounds;

  /// statsWithoutHints
  ///
  /// In ru, this message translates to:
  /// **'Без подсказок'**
  String get statsWithoutHints;

  /// statsHintsUsed
  ///
  /// In ru, this message translates to:
  /// **'Использовано подсказок'**
  String get statsHintsUsed;

  /// statsCurrentStreak
  ///
  /// In ru, this message translates to:
  /// **'Текущая серия'**
  String get statsCurrentStreak;

  /// statsBestStreak
  ///
  /// In ru, this message translates to:
  /// **'Лучшая серия'**
  String get statsBestStreak;

  /// statsCrystalsEarned
  ///
  /// In ru, this message translates to:
  /// **'Заработано кристаллов'**
  String get statsCrystalsEarned;

  /// appVersionUnavailable
  ///
  /// In ru, this message translates to:
  /// **'КроссСлов · версия недоступна'**
  String get appVersionUnavailable;

  /// dictionaryLicenseTitle
  ///
  /// In ru, this message translates to:
  /// **'Лицензия словаря'**
  String get dictionaryLicenseTitle;

  /// dictionaryLicenseMenu
  ///
  /// In ru, this message translates to:
  /// **'Лицензия английского словаря'**
  String get dictionaryLicenseMenu;

  /// licenseLoading
  ///
  /// In ru, this message translates to:
  /// **'Загрузка лицензии…'**
  String get licenseLoading;

  /// contactOpenFailed
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть приложение. Скопируйте контакт.'**
  String get contactOpenFailed;

  /// contactCopied
  ///
  /// In ru, this message translates to:
  /// **'Контакт скопирован'**
  String get contactCopied;

  /// aboutTitle
  ///
  /// In ru, this message translates to:
  /// **'Об игре'**
  String get aboutTitle;

  /// howToTitle
  ///
  /// In ru, this message translates to:
  /// **'Как играть'**
  String get howToTitle;

  /// privacyTitle
  ///
  /// In ru, this message translates to:
  /// **'Политика конфиденциальности'**
  String get privacyTitle;

  /// termsTitle
  ///
  /// In ru, this message translates to:
  /// **'Пользовательское соглашение'**
  String get termsTitle;

  /// feedbackTitle
  ///
  /// In ru, this message translates to:
  /// **'Обратная связь'**
  String get feedbackTitle;

  /// feedbackDetailsTitle
  ///
  /// In ru, this message translates to:
  /// **'Что указать'**
  String get feedbackDetailsTitle;

  /// aboutBody
  ///
  /// In ru, this message translates to:
  /// **'«КроссСлов» — игра о путешествии через мир слов. Соединяйте буквы, находите слова и заполняйте кроссворды. Проходите уровни и открывайте новые главы.'**
  String get aboutBody;

  /// howToConnectTitle
  ///
  /// In ru, this message translates to:
  /// **'1. Соединяйте'**
  String get howToConnectTitle;

  /// howToConnectBody
  ///
  /// In ru, this message translates to:
  /// **'Проведите пальцем или мышью от одной буквы к другой. Каждую букву можно выбрать один раз за слово.'**
  String get howToConnectBody;

  /// howToFindTitle
  ///
  /// In ru, this message translates to:
  /// **'2. Находите слова'**
  String get howToFindTitle;

  /// howToFindBody
  ///
  /// In ru, this message translates to:
  /// **'Правильное слово появится в кроссворде. Заполните все слова, чтобы пройти уровень.'**
  String get howToFindBody;

  /// howToHintTitle
  ///
  /// In ru, this message translates to:
  /// **'3. Если застряли'**
  String get howToHintTitle;

  /// howToHintBody
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте перемешать буквы: иногда это наталкивает на слово! Или откройте одну клетку подсказкой.'**
  String get howToHintBody;

  /// feedbackBody
  ///
  /// In ru, this message translates to:
  /// **'Нашли ошибку или хотите предложить улучшение «КроссСлов»? Напишите разработчику по электронной почте или в Telegram.'**
  String get feedbackBody;

  /// feedbackDetailsBody
  ///
  /// In ru, this message translates to:
  /// **'Опишите, что произошло, на каком уровне и какого результата вы ожидали. Сообщение отправляете вы сами через выбранное приложение.'**
  String get feedbackDetailsBody;

  /// levelLabel
  ///
  /// In ru, this message translates to:
  /// **'УРОВЕНЬ {level}'**
  String levelLabel(int level);

  /// chapterLabel
  ///
  /// In ru, this message translates to:
  /// **'Глава {number} · {name}'**
  String chapterLabel(int number, String name);

  /// chapterOpeningLabel
  ///
  /// In ru, this message translates to:
  /// **'ГЛАВА {number}'**
  String chapterOpeningLabel(int number);

  /// endlessHomeSummary
  ///
  /// In ru, this message translates to:
  /// **'Бесконечная игра · {count}'**
  String endlessHomeSummary(int count);

  /// roundLabel
  ///
  /// In ru, this message translates to:
  /// **'Раунд {round}'**
  String roundLabel(int round);

  /// appVersion
  ///
  /// In ru, this message translates to:
  /// **'КроссСлов · версия {version}'**
  String appVersion(String version);

  /// levelsLoadError
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить уровни: {error}'**
  String levelsLoadError(String error);

  /// copyContactTooltip
  ///
  /// In ru, this message translates to:
  /// **'Скопировать {contact}'**
  String copyContactTooltip(String contact);

  /// achievementChapterDescription
  ///
  /// In ru, this message translates to:
  /// **'Пройти главу «{chapter}»'**
  String achievementChapterDescription(String chapter);

  /// achievementLargeDescription
  ///
  /// In ru, this message translates to:
  /// **'Пройти уровень с {count} или более словами'**
  String achievementLargeDescription(int count);

  /// campaignFinalSummary
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{Пройден {count} уровень} few{Пройдено {count} уровня} many{Пройдено {count} уровней} other{Пройдено {count} уровня}}'**
  String campaignFinalSummary(int count);

  /// allLevelsCompleted
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{Весь {count} уровень пройден} few{Все {count} уровня пройдены} many{Все {count} уровней пройдены} other{Все {count} уровня пройдены}}'**
  String allLevelsCompleted(int count);

  /// achievementLevelsDescription
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{Пройти {count} уровень} few{Пройти {count} уровня} many{Пройти {count} уровней} other{Пройти {count} уровня}}'**
  String achievementLevelsDescription(int count);

  /// achievementWordsDescription
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{Открыть {count} слово} few{Открыть {count} слова} many{Открыть {count} слов} other{Открыть {count} слова}}'**
  String achievementWordsDescription(int count);

  /// achievementNoHintsDescription
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{Пройти {count} уровень без подсказок} few{Пройти {count} уровня без подсказок} many{Пройти {count} уровней без подсказок} other{Пройти {count} уровня без подсказок}}'**
  String achievementNoHintsDescription(int count);

  /// chapterForest
  ///
  /// In ru, this message translates to:
  /// **'Лес'**
  String get chapterForest;

  /// chapterLake
  ///
  /// In ru, this message translates to:
  /// **'Озеро'**
  String get chapterLake;

  /// chapterMountains
  ///
  /// In ru, this message translates to:
  /// **'Горы'**
  String get chapterMountains;

  /// chapterCastle
  ///
  /// In ru, this message translates to:
  /// **'Замок'**
  String get chapterCastle;

  /// chapterNorth
  ///
  /// In ru, this message translates to:
  /// **'Север'**
  String get chapterNorth;

  /// sceneForest01
  ///
  /// In ru, this message translates to:
  /// **'Лесная опушка'**
  String get sceneForest01;

  /// sceneForest02
  ///
  /// In ru, this message translates to:
  /// **'Глубокий лес'**
  String get sceneForest02;

  /// sceneForest03
  ///
  /// In ru, this message translates to:
  /// **'Край леса'**
  String get sceneForest03;

  /// sceneLake01
  ///
  /// In ru, this message translates to:
  /// **'Берег озера'**
  String get sceneLake01;

  /// sceneLake02
  ///
  /// In ru, this message translates to:
  /// **'Вдоль озера'**
  String get sceneLake02;

  /// sceneLake03
  ///
  /// In ru, this message translates to:
  /// **'Поселение у воды'**
  String get sceneLake03;

  /// sceneLake04
  ///
  /// In ru, this message translates to:
  /// **'Путь к горам'**
  String get sceneLake04;

  /// sceneMountains01
  ///
  /// In ru, this message translates to:
  /// **'Начало подъёма'**
  String get sceneMountains01;

  /// sceneMountains02
  ///
  /// In ru, this message translates to:
  /// **'Высокогорье'**
  String get sceneMountains02;

  /// sceneMountains03
  ///
  /// In ru, this message translates to:
  /// **'Горный перевал'**
  String get sceneMountains03;

  /// sceneMountains04
  ///
  /// In ru, this message translates to:
  /// **'Дорога к замку'**
  String get sceneMountains04;

  /// sceneCastle01
  ///
  /// In ru, this message translates to:
  /// **'У ворот'**
  String get sceneCastle01;

  /// sceneCastle02
  ///
  /// In ru, this message translates to:
  /// **'Старый двор'**
  String get sceneCastle02;

  /// sceneCastle03
  ///
  /// In ru, this message translates to:
  /// **'Высокая башня'**
  String get sceneCastle03;

  /// sceneCastle04
  ///
  /// In ru, this message translates to:
  /// **'Северные ворота'**
  String get sceneCastle04;

  /// sceneNorth01
  ///
  /// In ru, this message translates to:
  /// **'Северная долина'**
  String get sceneNorth01;

  /// sceneNorth02
  ///
  /// In ru, this message translates to:
  /// **'Ледяные просторы'**
  String get sceneNorth02;

  /// sceneNorth03
  ///
  /// In ru, this message translates to:
  /// **'Северное сияние'**
  String get sceneNorth03;

  /// sceneNorth04
  ///
  /// In ru, this message translates to:
  /// **'Последний приют'**
  String get sceneNorth04;

  /// sceneNorth05
  ///
  /// In ru, this message translates to:
  /// **'Край света'**
  String get sceneNorth05;

  /// achievementFirstStepTitle
  ///
  /// In ru, this message translates to:
  /// **'Первый шаг'**
  String get achievementFirstStepTitle;

  /// achievementChapter1Title
  ///
  /// In ru, this message translates to:
  /// **'Следопыт'**
  String get achievementChapter1Title;

  /// achievementChapter2Title
  ///
  /// In ru, this message translates to:
  /// **'У озера'**
  String get achievementChapter2Title;

  /// achievementChapter3Title
  ///
  /// In ru, this message translates to:
  /// **'Покоритель вершин'**
  String get achievementChapter3Title;

  /// achievementChapter4Title
  ///
  /// In ru, this message translates to:
  /// **'Хранитель замка'**
  String get achievementChapter4Title;

  /// achievementChapter5Title
  ///
  /// In ru, this message translates to:
  /// **'На краю Севера'**
  String get achievementChapter5Title;

  /// achievementCampaignTitle
  ///
  /// In ru, this message translates to:
  /// **'КроссСлов'**
  String get achievementCampaignTitle;

  /// achievementWords100Title
  ///
  /// In ru, this message translates to:
  /// **'Словарный запас'**
  String get achievementWords100Title;

  /// achievementWords500Title
  ///
  /// In ru, this message translates to:
  /// **'Знаток слов'**
  String get achievementWords500Title;

  /// achievementWords1000Title
  ///
  /// In ru, this message translates to:
  /// **'Эрудит'**
  String get achievementWords1000Title;

  /// achievementNoHints10Title
  ///
  /// In ru, this message translates to:
  /// **'Самостоятельный'**
  String get achievementNoHints10Title;

  /// achievementNoHints50Title
  ///
  /// In ru, this message translates to:
  /// **'Мастер'**
  String get achievementNoHints50Title;

  /// achievementLargeCrosswordTitle
  ///
  /// In ru, this message translates to:
  /// **'Большой кроссворд'**
  String get achievementLargeCrosswordTitle;

  /// achievementCategoryJourney
  ///
  /// In ru, this message translates to:
  /// **'Путешествие'**
  String get achievementCategoryJourney;

  /// achievementCategoryWords
  ///
  /// In ru, this message translates to:
  /// **'Слова'**
  String get achievementCategoryWords;

  /// achievementCategoryWithoutHints
  ///
  /// In ru, this message translates to:
  /// **'Без подсказок'**
  String get achievementCategoryWithoutHints;

  /// achievementCategoryLargeCrosswords
  ///
  /// In ru, this message translates to:
  /// **'Большие Crossword'**
  String get achievementCategoryLargeCrosswords;

  /// Complete the entire campaign
  ///
  /// In ru, this message translates to:
  /// **'Пройти все {count} уровней'**
  String achievementCampaignDescription(int count);

  /// Full Privacy Policy, preserving the current approved Russian source.
  ///
  /// In ru, this message translates to:
  /// **'«КроссСлов» не требует регистрации и не запрашивает имя, номер телефона, адрес электронной почты или иные персональные данные для использования игры.\n\nИгровой прогресс, найденные слова незавершённого уровня, баланс кристаллов, статистика, достижения, состояние бесконечной игры, настройки и выбранная тема сохраняются локально на устройстве пользователя. Облачная синхронизация игровых данных не используется.\n\nПриложение не передаёт игровой прогресс разработчику и не использует его для идентификации пользователя. Локальные игровые данные можно удалить средствами операционной системы, очистив данные приложения, либо удалив приложение с устройства.\n\nПри обращении к разработчику по электронной почте или через Telegram пользователь самостоятельно передаёт данные выбранному сервису связи. Обработка таких данных осуществляется в соответствии с правилами соответствующего сервиса.\n\n'**
  String get privacyBody;

  /// Full EULA, preserving the current approved Russian source.
  ///
  /// In ru, this message translates to:
  /// **'«КроссСлов» — игра в слова. Используя приложение, пользователь соглашается с условиями настоящего Пользовательского соглашения.\n\nИгра предоставляется для личного некоммерческого использования. Пользователь может проходить кампанию, разгадывать кроссворды, использовать подсказки, получать достижения и после завершения кампании продолжать игру в бесконечном режиме.\n\nКристаллы являются исключительно внутриигровым ресурсом. Они могут начисляться за игровые действия и расходоваться на предусмотренные игрой функции. Кристаллы не являются денежными средствами, не имеют денежной стоимости и не подлежат обмену на деньги.\n\nИгровой прогресс и настройки сохраняются локально на устройстве. Пользователь самостоятельно отвечает за сохранность данных своего устройства. При удалении приложения, очистке его данных, сбросе устройства или в иных случаях локальные игровые данные могут быть утрачены.\n\nРазработчик вправе выпускать обновления, исправлять ошибки, изменять игровой баланс, содержание, оформление и функциональные возможности приложения. Обновления могут отличаться от предыдущих версий игры.\n\nПриложение предоставляется в состоянии «как есть». Разработчик стремится обеспечивать корректную работу игры, однако не гарантирует отсутствие программных ошибок или совместимость со всеми устройствами и версиями операционной системы.\n\nПользователь не должен пытаться вмешиваться в работу приложения, распространять изменённые версии приложения от имени разработчика либо использовать материалы игры с нарушением применимого законодательства и прав правообладателей.\n\n'**
  String get termsBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
