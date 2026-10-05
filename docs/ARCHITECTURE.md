# Архитектура КроссСлов

Документ описывает код в состоянии на 5 октября 2026 года. Это Flutter-приложение без отдельного backend и без внешнего state management.

## Поток приложения

```text
main.dart
  └─ CrossSlowApp
       ├─ загружает тему, уровни и локальный прогресс
       ├─ SplashScreen → HomeScreen / ChapterTransitionScreen / ChapterSceneRevealScreen
       │                    └─ MenuScreen → Статистика / Достижения / ИНФО
       └─ GameScreen
            ├─ LetterBoard → слово → GameController
            ├─ CrosswordBoard ← найденные слова / подсказки
            └─ победа → сохранение → следующий уровень / новая глава / финал / Endless
```

`CrossSlowApp` в [lib/app/cross_slow_app.dart](../lib/app/cross_slow_app.dart) владеет навигацией, `CampaignProgress` и выбранной темой. При запуске параллельно с заставкой он читает тему, уровни и сохранённый прогресс. Двухсекундный таймер заставки запускается после первого кадра `doc/load.png`.

При победе `CampaignProgress.complete` атомарно для игрового состояния отмечает ID уровня, обновляет статистику, начисляет 3 кристалла и ставит переход главы при достижении границы. Повторное завершение того же ID ничего не меняет. `pendingSave` сериализует записи в `SharedPreferencesAsync`. Переход главы хранится как `pendingChapterId`: после закрытия приложения экран главы появится снова, пока игрок не подтвердит его. После уровня 150 один раз показывается финал на `north_05`, затем Home открывает Endless. Уровень 151 не создаётся.

## Где находится код

| Область | Файлы | Ответственность |
|---|---|---|
| Вход и навигация | `lib/main.dart`, `lib/app/cross_slow_app.dart` | `MaterialApp`, загрузка, переходы, сохранение |
| Данные уровней | `assets/levels.json`, `lib/features/game/models/level.dart`, `lib/features/game/data/level_repository.dart` | Утверждённые 150 уровней, JSON → модели |
| Главы | `lib/campaign/campaign_chapter.dart`, `chapter_transition_screen.dart` | Границы пяти глав, прогресс внутри главы, переходы |
| Сцены Home | `lib/campaign/chapter_scene.dart`, `chapter_scene_backdrop.dart`, `chapter_ambient_effects.dart`, `chapter_scene_reveal_screen.dart` | Фон по ID уровня, focal alignment, дешёвые эффекты, одноразовое открытие сцены |
| Правила игры | `lib/features/game/controller/game_controller.dart` | Проверка слова, найденные слова, открытые подсказкой клетки, критерий победы |
| Игровой экран | `lib/features/game/game_screen.dart` | Компоновка, обратная связь, победа, вызовы контроллера |
| Буквы и жесты | `lib/features/game/widgets/letter_board.dart` | Геометрия, выбор физического экземпляра буквы, линия, перемешивание |
| Кроссворд | `lib/features/game/widgets/crossword_board.dart` | Клетки, анимированное открытие и подсветка |
| Главный экран | `lib/features/home/home_screen.dart` | Текущий уровень, глава, прогресс; после кампании — счётчик Endless и «Играть» |
| Меню и справка | `lib/features/menu/menu_screen.dart`, `info_content.dart` | Тема, статистика, достижения, тексты и контакты |
| Оформление | `lib/core/theme/game_theme.dart`, `lib/core/widgets/` | Две темы, палитра, pixel UI, фоны |
| Сохранение | `lib/progress/campaign_progress.dart`, `progress_repository.dart`, `theme_repository.dart` | Кампания, активный Endless-раунд, статистика, тема |
| Достижения | `lib/progress/achievements.dart` | 13 определений и единые правила разблокировки |

## Формат уровня

Источник — [assets/levels.json](../assets/levels.json). Уровень задаёт ID, доступные буквы и размещение каждого слова:

```json
{
  "id": 1,
  "letters": ["К", "О", "Т"],
  "words": [
    {"text": "КОТ", "row": 2, "col": 0, "direction": "across"},
    {"text": "ТОК", "row": 0, "col": 0, "direction": "down"}
  ]
}
```

Координаты `row` и `col` начинаются с нуля. `direction` должен быть `across` или `down`; [WordPlacement.fromJson](../lib/features/game/models/level.dart) считает любой вариант, кроме `down`, горизонтальным, поэтому опечатка может тихо изменить сетку. Число строк и столбцов выводится из крайних координат слов. Модель предполагает непустой список `words`.

Уровень нужно составлять так, чтобы каждое слово собиралось из `letters` с учётом повторяющихся букв; в пересечении слов буквы должны совпадать. Candidate campaign проверяется валидатором `tools/level_generator/test_campaign.py` до переноса в production. Flutter тест проверяет загрузку 150 ID и уникальность наборов букв.

## Правила и отображение

`GameController` хранит `found` (тексты принятых слов) и `revealed` (координаты клеток, открытых подсказкой). `submit` возвращает `correct`, `alreadyFound`, `validNotInCrossword` или `unknown`. Обязательные слова текущего Crossword принимаются по данным уровня; для остальных проверяются кратность доступных букв и вхождение в `assets/game_words.txt`. В runtime-словаре 2 089 слов длиной 3–7 букв; `GameDictionary` приводит ввод к верхнему регистру и заменяет `Ё→Е`, но не `Й→И`. Победа наступает, когда число найденных обязательных слов равно числу слов уровня. `revealOne` выбирает случайную закрытую физическую клетку. Подсказка списывает 10 кристаллов только при успешном открытии клетки.

`LetterBoard` хранит `order` — порядок физических экземпляров букв. `selected` содержит их индексы, а не символы, что позволяет уровням с повторяющимися буквами работать корректно. Обработчики `Listener` реагируют на touch и mouse pointer; при отпускании собранное слово передаётся в `GameScreen`. `shuffle()` перемешивает только `order`, а `AnimatedPositioned` визуально переносит буквы. Размер панели ограничен 270×270; `_positions` задаёт компактную геометрию для 3–7 букв. При добавлении букв сверх этого диапазона потребуется новая геометрия.

`CrosswordBoard` слушает `GameController`. Подсказка открывает клетку сразу; принятое слово раскрывается по буквам с задержкой `130 + i × 75` мс. `visible`, `glowing` и `processedWords` — локальное состояние анимации виджета, оно не сохраняется между входами в уровень. Сетка масштабируется по доступной ширине/высоте с максимальной стороной клетки 74 px.

На узком экране игра располагает кроссворд над панелью букв; при ширине от 760 px ставит их рядом. Home меняет отдельные размеры при ширине от 740 px. Сцена берётся из `ChapterScenes` для уровня; Game использует тот же WebP без ambient и с усиленным слоем читаемости. Для Endless всегда применяется `north_05`. Старый `ScenicBackground` остаётся fallback для уровней без сцены.

## Сохранение и статистика

`SharedPreferencesAsync` использует следующие ключи:

| Ключ | Тип | Смысл |
|---|---|---|
| `campaign_150_state_v2` | JSON string | Кампания, бесконечные раунды, найденные слова, подсказки, серии, кристаллы, достижения и ожидающий переход главы |
| `light_theme` | `bool` | Светлая тема; по умолчанию `false` |

Home определяет главу через `CampaignChapters.forLevel(currentLevel)` и показывает позицию текущего уровня внутри неё (например, 37 → 17/30). `wordsFound` растёт только при первом открытии обязательного слова, `hintsUsed` — только при успешном открытии клетки. Для достижений хранятся ID и время разблокировки. Повторные события не увеличивают завершения и награды.

После первого завершения уровня 150 флаг `campaignFinalSeen` управляет одноразовым финалом на `north_05`. Campaign `currentLevel` и `completed` остаются 150/150. Endless берёт случайный шаблон из уровней 50–150 и исключает последние 10 выбранных source ID; при маленьком pool фильтр ослабляется. `activeEndlessSourceLevelId`, `endlessFoundWords`, `endlessHinted`, `recentEndlessSourceLevelIds` и `endlessRoundsCompleted` хранятся в том же snapshot как необязательные поля схемы 2. Это позволяет читать старые сохранения. Endless использует тот же `GameScreen`, но принудительно показывает `north_05` и номер раунда; исходный ID игроку не показывается. Статистика и кристаллы растут по тем же правилам, campaign completion и достижения не меняются.

`ChapterScenes.forLevel` выбирает одну из 20 сцен для всех уровней 1–150; `HomeScreen` использует её WebP-фон с `BoxFit.cover`, слой `ChapterAmbientEffects` и локальный градиент внизу. Исходные PNG находятся в `doc/`, runtime WebP — в `assets/backgrounds/`. При первом достижении начального уровня каждой сцены `ChapterSceneRevealScreen` показывает пейзаж до обычного Home. Подтверждённые ID сцен хранятся в `seenScenes`; старые сохранения версии 2 читаются с пустым набором. Эффекты имеют один ticker на сцену, перерисовывают только `CustomPaint` внутри `RepaintBoundary` и отключаются при `MediaQuery.disableAnimationsOf`.

| Глава | Сцены по порядку и диапазоны уровней |
|---|---|
| Лес | `forest_01` 1–7, `forest_02` 8–14, `forest_03` 15–20 |
| Озеро | `lake_01` 21–27, `lake_02` 28–34, `lake_03` 35–42, `lake_04` 43–50 |
| Горы | `mountains_01` 51–57, `mountains_02` 58–64, `mountains_03` 65–72, `mountains_04` 73–80 |
| Замок | `castle_01` 81–87, `castle_02` 88–94, `castle_03` 95–102, `castle_04` 103–110 |
| Север | `north_01` 111–118, `north_02` 119–126, `north_03` 127–134, `north_04` 135–142, `north_05` 143–150 |

Старые `current_level`, `completed_levels`, `crystal_balance` относятся к несовместимой тестовой кампании. При первом запуске версии 2 записывается чистое состояние кампании, затем эти три ключа удаляются; `light_theme` сохраняется. При дальнейшем изменении схемы нужна новая миграция.

## Оформление и внешние пакеты

`GameTheme.dark/light` задают `ThemeData`; [GamePalette](../lib/core/theme/game_theme.dart) — `ThemeExtension` с цветами панелей, кнопок, клеток, буквенной панели и текста. `PixelPanel`, `PixelButton`, `PixelCell` и фон читают эту палитру через `GamePalette.of(context)`. Часть разовых цветов в `GameScreen` остаётся константами — проверяйте обе темы после визуальных правок.

[SlyFlEffectsLab](../pubspec.yaml) подключён Git-зависимостью на commit `32597b0f828df6a8d99aa77815baf1debabbd86f`. `GameScreen` импортирует его публичный `sly_fl_effects.dart` и создаёт `EffectPlayer` с `ConfettiConfig` только при завершении уровня. Локальная папка `C:\Project\SlyFlEffectsLab` служит исходным кодом для изучения API, но сборка от неё не зависит. `package_info_plus` показывает версию приложения в «ИНФО», `url_launcher` открывает почту и Telegram по действию пользователя.

Графика: `doc/load.png` — заставка; `doc/logo.png` — логотип Home; `doc/{forest,lake,mountains,castle,north}_XX.png` — исходники сцен; соответствующие WebP в `assets/backgrounds/` — runtime-фоны. `forest_portrait.png` и `forest_wide.png` остаются fallback-фонами. `doc/main.jpg` и `doc/screen.jpg` — референсные эскизы, не включённые в `flutter.assets`.
