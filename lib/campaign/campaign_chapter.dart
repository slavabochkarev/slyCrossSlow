class CampaignChapter {
  const CampaignChapter({
    required this.id,
    required this.name,
    required this.firstLevel,
    required this.lastLevel,
  });

  final int id;
  final String name;
  final int firstLevel;
  final int lastLevel;

  int get totalLevels => lastLevel - firstLevel + 1;

  bool contains(int level) => firstLevel <= level && level <= lastLevel;

  /// One-based position shown on Home (level 37 in Озеро is 17 / 30).
  int positionOf(int level) => (level - firstLevel + 1).clamp(1, totalLevels);

  int completedCount(Set<int> completed) => completed.where(contains).length;
}

class CampaignChapters {
  CampaignChapters._();

  static const all = <CampaignChapter>[
    CampaignChapter(id: 1, name: 'Лес', firstLevel: 1, lastLevel: 20),
    CampaignChapter(id: 2, name: 'Озеро', firstLevel: 21, lastLevel: 50),
    CampaignChapter(id: 3, name: 'Горы', firstLevel: 51, lastLevel: 80),
    CampaignChapter(id: 4, name: 'Замок', firstLevel: 81, lastLevel: 110),
    CampaignChapter(id: 5, name: 'Север', firstLevel: 111, lastLevel: 150),
  ];

  static CampaignChapter forLevel(int level) => all.firstWhere(
    (chapter) => chapter.contains(level),
    orElse: () => throw RangeError.value(level, 'level'),
  );

  static CampaignChapter? afterLevel(int level) {
    final current = forLevel(level);
    if (current.lastLevel != level || current.id == all.length) return null;
    return all[current.id];
  }
}
