// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get menuTitle => 'МЕНЮ';

  @override
  String get gameTab => 'ИГРА';

  @override
  String get infoTab => 'ИНФО';

  @override
  String get menuTooltip => 'Меню';

  @override
  String get journeyTitle => 'ПУТЕШЕСТВИЕ';

  @override
  String get campaignCompleted => 'Кампания пройдена';

  @override
  String get playButton => 'ИГРАТЬ';

  @override
  String get continueButton => 'ПРОДОЛЖИТЬ';

  @override
  String get backHomeTooltip => 'На главную';

  @override
  String get endlessTitle => 'БЕСКОНЕЧНАЯ ИГРА';

  @override
  String get shuffleTooltip => 'Перемешать';

  @override
  String get revealLetterTooltip => 'Открыть букву';

  @override
  String get themeSection => 'ТЕМА';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get crosswordLanguage => 'Язык кроссвордов';

  @override
  String get interfaceLanguage => 'Язык интерфейса';

  @override
  String get englishUnavailable =>
      'Доступен после добавления английских уровней';

  @override
  String get progressSection => 'ПРОГРЕСС';

  @override
  String get statisticsTitle => 'Статистика';

  @override
  String get achievementsTitle => 'Достижения';

  @override
  String get wordAlreadyFound => 'УЖЕ НАЙДЕНО';

  @override
  String get wordOutsideCrossword => 'СЛОВО ЕСТЬ! НО НЕ В ЭТОМ КРОССВОРДЕ';

  @override
  String get tryAgain => 'ПОПРОБУЙТЕ ЕЩЁ';

  @override
  String get notEnoughCrystals => 'НЕДОСТАТОЧНО КРИСТАЛЛОВ';

  @override
  String get letterRevealed => 'БУКВА ОТКРЫТА';

  @override
  String get roundCompletedTitle => '★  РАУНД ЗАВЕРШЁН  ★';

  @override
  String get levelCompletedTitle => '★  УРОВЕНЬ ПРОЙДЕН  ★';

  @override
  String get journeyCompletedTitle => '★  ПУТЕШЕСТВИЕ ЗАВЕРШЕНО  ★';

  @override
  String get allWordsSolved => 'Все слова разгаданы';

  @override
  String get nextRoundButton => 'СЛЕДУЮЩИЙ РАУНД';

  @override
  String get continuePlayingButton => 'ПРОДОЛЖИТЬ ИГРАТЬ';

  @override
  String get backHomeButton => 'НА ГЛАВНУЮ';

  @override
  String get campaignFinalTitle => 'ПУТЕШЕСТВИЕ ЗАВЕРШЕНО';

  @override
  String get campaignFinalCaption => 'Но слова не заканчиваются...';

  @override
  String get achievementToastTitle => '★ ДОСТИЖЕНИЕ ★';

  @override
  String get journeyContinues => 'Путь продолжается...';

  @override
  String get statsLevelsCompleted => 'Пройдено уровней';

  @override
  String get statsWordsFound => 'Найдено слов';

  @override
  String get statsEndlessRounds => 'Бесконечные раунды';

  @override
  String get statsWithoutHints => 'Без подсказок';

  @override
  String get statsHintsUsed => 'Использовано подсказок';

  @override
  String get statsCurrentStreak => 'Текущая серия';

  @override
  String get statsBestStreak => 'Лучшая серия';

  @override
  String get statsCrystalsEarned => 'Заработано кристаллов';

  @override
  String get appVersionUnavailable => 'КроссСлов · версия недоступна';

  @override
  String get dictionaryLicenseTitle => 'Лицензия словаря';

  @override
  String get dictionaryLicenseMenu => 'Лицензия английского словаря';

  @override
  String get licenseLoading => 'Загрузка лицензии…';

  @override
  String get contactOpenFailed =>
      'Не удалось открыть приложение. Скопируйте контакт.';

  @override
  String get contactCopied => 'Контакт скопирован';

  @override
  String get aboutTitle => 'Об игре';

  @override
  String get howToTitle => 'Как играть';

  @override
  String get privacyTitle => 'Политика конфиденциальности';

  @override
  String get termsTitle => 'Пользовательское соглашение';

  @override
  String get feedbackTitle => 'Обратная связь';

  @override
  String get feedbackDetailsTitle => 'Что указать';

  @override
  String get aboutBody =>
      '«КроссСлов» — игра о путешествии через мир слов. Соединяйте буквы, находите слова и заполняйте кроссворды. Проходите уровни и открывайте новые главы.';

  @override
  String get howToConnectTitle => '1. Соединяйте';

  @override
  String get howToConnectBody =>
      'Проведите пальцем или мышью от одной буквы к другой. Каждую букву можно выбрать один раз за слово.';

  @override
  String get howToFindTitle => '2. Находите слова';

  @override
  String get howToFindBody =>
      'Правильное слово появится в кроссворде. Заполните все слова, чтобы пройти уровень.';

  @override
  String get howToHintTitle => '3. Если застряли';

  @override
  String get howToHintBody =>
      'Попробуйте перемешать буквы: иногда это наталкивает на слово! Или откройте одну клетку подсказкой.';

  @override
  String get feedbackBody =>
      'Нашли ошибку или хотите предложить улучшение «КроссСлов»? Напишите разработчику по электронной почте или в Telegram.';

  @override
  String get feedbackDetailsBody =>
      'Опишите, что произошло, на каком уровне и какого результата вы ожидали. Сообщение отправляете вы сами через выбранное приложение.';

  @override
  String levelLabel(int level) {
    return 'УРОВЕНЬ $level';
  }

  @override
  String chapterLabel(int number, String name) {
    return 'Глава $number · $name';
  }

  @override
  String chapterOpeningLabel(int number) {
    return 'ГЛАВА $number';
  }

  @override
  String endlessHomeSummary(int count) {
    return 'Бесконечная игра · $count';
  }

  @override
  String roundLabel(int round) {
    return 'Раунд $round';
  }

  @override
  String appVersion(String version) {
    return 'КроссСлов · версия $version';
  }

  @override
  String levelsLoadError(String error) {
    return 'Не удалось загрузить уровни: $error';
  }

  @override
  String copyContactTooltip(String contact) {
    return 'Скопировать $contact';
  }

  @override
  String achievementChapterDescription(String chapter) {
    return 'Пройти главу «$chapter»';
  }

  @override
  String achievementLargeDescription(int count) {
    return 'Пройти уровень с $count или более словами';
  }

  @override
  String campaignFinalSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пройдено $count уровня',
      many: 'Пройдено $count уровней',
      few: 'Пройдено $count уровня',
      one: 'Пройден $count уровень',
    );
    return '$_temp0';
  }

  @override
  String allLevelsCompleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Все $count уровня пройдены',
      many: 'Все $count уровней пройдены',
      few: 'Все $count уровня пройдены',
      one: 'Весь $count уровень пройден',
    );
    return '$_temp0';
  }

  @override
  String achievementLevelsDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пройти $count уровня',
      many: 'Пройти $count уровней',
      few: 'Пройти $count уровня',
      one: 'Пройти $count уровень',
    );
    return '$_temp0';
  }

  @override
  String achievementWordsDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Открыть $count слова',
      many: 'Открыть $count слов',
      few: 'Открыть $count слова',
      one: 'Открыть $count слово',
    );
    return '$_temp0';
  }

  @override
  String achievementNoHintsDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пройти $count уровня без подсказок',
      many: 'Пройти $count уровней без подсказок',
      few: 'Пройти $count уровня без подсказок',
      one: 'Пройти $count уровень без подсказок',
    );
    return '$_temp0';
  }

  @override
  String get chapterForest => 'Лес';

  @override
  String get chapterLake => 'Озеро';

  @override
  String get chapterMountains => 'Горы';

  @override
  String get chapterCastle => 'Замок';

  @override
  String get chapterNorth => 'Север';

  @override
  String get sceneForest01 => 'Лесная опушка';

  @override
  String get sceneForest02 => 'Глубокий лес';

  @override
  String get sceneForest03 => 'Край леса';

  @override
  String get sceneLake01 => 'Берег озера';

  @override
  String get sceneLake02 => 'Вдоль озера';

  @override
  String get sceneLake03 => 'Поселение у воды';

  @override
  String get sceneLake04 => 'Путь к горам';

  @override
  String get sceneMountains01 => 'Начало подъёма';

  @override
  String get sceneMountains02 => 'Высокогорье';

  @override
  String get sceneMountains03 => 'Горный перевал';

  @override
  String get sceneMountains04 => 'Дорога к замку';

  @override
  String get sceneCastle01 => 'У ворот';

  @override
  String get sceneCastle02 => 'Старый двор';

  @override
  String get sceneCastle03 => 'Высокая башня';

  @override
  String get sceneCastle04 => 'Северные ворота';

  @override
  String get sceneNorth01 => 'Северная долина';

  @override
  String get sceneNorth02 => 'Ледяные просторы';

  @override
  String get sceneNorth03 => 'Северное сияние';

  @override
  String get sceneNorth04 => 'Последний приют';

  @override
  String get sceneNorth05 => 'Край света';

  @override
  String get achievementFirstStepTitle => 'Первый шаг';

  @override
  String get achievementChapter1Title => 'Следопыт';

  @override
  String get achievementChapter2Title => 'У озера';

  @override
  String get achievementChapter3Title => 'Покоритель вершин';

  @override
  String get achievementChapter4Title => 'Хранитель замка';

  @override
  String get achievementChapter5Title => 'На краю Севера';

  @override
  String get achievementCampaignTitle => 'КроссСлов';

  @override
  String get achievementWords100Title => 'Словарный запас';

  @override
  String get achievementWords500Title => 'Знаток слов';

  @override
  String get achievementWords1000Title => 'Эрудит';

  @override
  String get achievementNoHints10Title => 'Самостоятельный';

  @override
  String get achievementNoHints50Title => 'Мастер';

  @override
  String get achievementLargeCrosswordTitle => 'Большой кроссворд';

  @override
  String get achievementCategoryJourney => 'Путешествие';

  @override
  String get achievementCategoryWords => 'Слова';

  @override
  String get achievementCategoryWithoutHints => 'Без подсказок';

  @override
  String get achievementCategoryLargeCrosswords => 'Большие Crossword';

  @override
  String achievementCampaignDescription(int count) {
    return 'Пройти все $count уровней';
  }

  @override
  String get privacyBody =>
      '«КроссСлов» не требует регистрации и не запрашивает имя, номер телефона, адрес электронной почты или иные персональные данные для использования игры.\n\nИгровой прогресс, найденные слова незавершённого уровня, баланс кристаллов, статистика, достижения, состояние бесконечной игры, настройки и выбранная тема сохраняются локально на устройстве пользователя. Облачная синхронизация игровых данных не используется.\n\nПриложение не передаёт игровой прогресс разработчику и не использует его для идентификации пользователя. Локальные игровые данные можно удалить средствами операционной системы, очистив данные приложения, либо удалив приложение с устройства.\n\nПри обращении к разработчику по электронной почте или через Telegram пользователь самостоятельно передаёт данные выбранному сервису связи. Обработка таких данных осуществляется в соответствии с правилами соответствующего сервиса.\n\n';

  @override
  String get termsBody =>
      '«КроссСлов» — игра в слова. Используя приложение, пользователь соглашается с условиями настоящего Пользовательского соглашения.\n\nИгра предоставляется для личного некоммерческого использования. Пользователь может проходить кампанию, разгадывать кроссворды, использовать подсказки, получать достижения и после завершения кампании продолжать игру в бесконечном режиме.\n\nКристаллы являются исключительно внутриигровым ресурсом. Они могут начисляться за игровые действия и расходоваться на предусмотренные игрой функции. Кристаллы не являются денежными средствами, не имеют денежной стоимости и не подлежат обмену на деньги.\n\nИгровой прогресс и настройки сохраняются локально на устройстве. Пользователь самостоятельно отвечает за сохранность данных своего устройства. При удалении приложения, очистке его данных, сбросе устройства или в иных случаях локальные игровые данные могут быть утрачены.\n\nРазработчик вправе выпускать обновления, исправлять ошибки, изменять игровой баланс, содержание, оформление и функциональные возможности приложения. Обновления могут отличаться от предыдущих версий игры.\n\nПриложение предоставляется в состоянии «как есть». Разработчик стремится обеспечивать корректную работу игры, однако не гарантирует отсутствие программных ошибок или совместимость со всеми устройствами и версиями операционной системы.\n\nПользователь не должен пытаться вмешиваться в работу приложения, распространять изменённые версии приложения от имени разработчика либо использовать материалы игры с нарушением применимого законодательства и прав правообладателей.\n\n';
}
