import '../campaign/campaign_chapter.dart';
import '../features/game/models/level.dart';
import 'campaign_progress.dart';

enum AchievementMetric {
  completed,
  chapter,
  words,
  withoutHints,
  largeCrossword,
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.metric,
    required this.target,
    this.chapter,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final AchievementMetric metric;
  final int target;
  final CampaignChapter? chapter;

  int progress(CampaignProgress state, List<Level> levels) => switch (metric) {
    AchievementMetric.completed => state.completedLevels,
    AchievementMetric.chapter => chapter!.completedCount(state.completed),
    AchievementMetric.words => state.wordsFound,
    AchievementMetric.withoutHints => state.levelsWithoutHints,
    AchievementMetric.largeCrossword =>
      levels.any(
            (level) =>
                level.words.length >= 15 && state.completed.contains(level.id),
          )
          ? 1
          : 0,
  };

  bool isUnlocked(CampaignProgress state) => state.unlockedAt.containsKey(id);
}

class AchievementRules {
  AchievementRules._();

  static final List<AchievementDefinition> all = [
    const AchievementDefinition(
      id: 'first_step',
      title: 'Первый шаг',
      description: 'Пройти 1 уровень',
      category: 'Путешествие',
      metric: AchievementMetric.completed,
      target: 1,
    ),
    for (final chapter in CampaignChapters.all)
      AchievementDefinition(
        id: 'chapter_${chapter.id}',
        title: switch (chapter.id) {
          1 => 'Следопыт',
          2 => 'У озера',
          3 => 'Покоритель вершин',
          4 => 'Хранитель замка',
          _ => 'На краю Севера',
        },
        description: 'Пройти главу «${chapter.name}»',
        category: 'Путешествие',
        metric: AchievementMetric.chapter,
        target: chapter.totalLevels,
        chapter: chapter,
      ),
    const AchievementDefinition(
      id: 'cross_slow',
      title: 'КроссСлов',
      description: 'Пройти все 150 уровней',
      category: 'Путешествие',
      metric: AchievementMetric.completed,
      target: 150,
    ),
    const AchievementDefinition(
      id: 'words_100',
      title: 'Словарный запас',
      description: 'Открыть 100 слов',
      category: 'Слова',
      metric: AchievementMetric.words,
      target: 100,
    ),
    const AchievementDefinition(
      id: 'words_500',
      title: 'Знаток слов',
      description: 'Открыть 500 слов',
      category: 'Слова',
      metric: AchievementMetric.words,
      target: 500,
    ),
    const AchievementDefinition(
      id: 'words_1000',
      title: 'Эрудит',
      description: 'Открыть 1000 слов',
      category: 'Слова',
      metric: AchievementMetric.words,
      target: 1000,
    ),
    const AchievementDefinition(
      id: 'no_hints_10',
      title: 'Самостоятельный',
      description: 'Пройти 10 уровней без подсказок',
      category: 'Без подсказок',
      metric: AchievementMetric.withoutHints,
      target: 10,
    ),
    const AchievementDefinition(
      id: 'no_hints_50',
      title: 'Мастер',
      description: 'Пройти 50 уровней без подсказок',
      category: 'Без подсказок',
      metric: AchievementMetric.withoutHints,
      target: 50,
    ),
    const AchievementDefinition(
      id: 'large_crossword',
      title: 'Большой кроссворд',
      description: 'Пройти уровень с 15 или более словами',
      category: 'Большие Crossword',
      metric: AchievementMetric.largeCrossword,
      target: 1,
    ),
  ];

  static List<AchievementDefinition> unlockNew(
    CampaignProgress state,
    List<Level> levels,
    DateTime now,
  ) {
    final unlocked = <AchievementDefinition>[];
    for (final achievement in all) {
      if (achievement.isUnlocked(state) ||
          achievement.progress(state, levels) < achievement.target) {
        continue;
      }
      state.unlockedAt[achievement.id] = now;
      unlocked.add(achievement);
    }
    return unlocked;
  }
}
