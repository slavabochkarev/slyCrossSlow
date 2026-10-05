import 'dart:math';

import '../campaign/campaign_chapter.dart';
import '../features/game/models/level.dart';

class CampaignProgress {
  static const hintCost = 10;

  CampaignProgress({
    this.currentLevel = 1,
    Set<int>? completed,
    this.wordsFound = 0,
    this.hintsUsed = 0,
    this.levelsWithoutHints = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.crystalsEarned = 0,
    this.crystals = 0,
    Map<int, Set<String>>? foundWords,
    Set<int>? hintedLevels,
    Map<String, DateTime>? unlockedAt,
    Set<String>? seenScenes,
    this.pendingChapterId,
    this.campaignFinalSeen = false,
    this.endlessRoundsCompleted = 0,
    this.activeEndlessSourceLevelId,
    Set<String>? endlessFoundWords,
    this.endlessHinted = false,
    List<int>? recentEndlessSourceLevelIds,
  }) : completed = completed ?? <int>{},
       foundWords = foundWords ?? <int, Set<String>>{},
       hintedLevels = hintedLevels ?? <int>{},
       unlockedAt = unlockedAt ?? <String, DateTime>{},
       seenScenes = seenScenes ?? <String>{},
       endlessFoundWords = endlessFoundWords ?? <String>{},
       recentEndlessSourceLevelIds = recentEndlessSourceLevelIds ?? <int>[];

  int currentLevel;
  final Set<int> completed;
  int wordsFound;
  int hintsUsed;
  int levelsWithoutHints;
  int currentStreak;
  int bestStreak;
  int crystalsEarned;
  int crystals;
  final Map<int, Set<String>> foundWords;
  final Set<int> hintedLevels;
  final Map<String, DateTime> unlockedAt;
  final Set<String> seenScenes;
  int? pendingChapterId;
  bool campaignFinalSeen;
  int endlessRoundsCompleted;
  int? activeEndlessSourceLevelId;
  final Set<String> endlessFoundWords;
  bool endlessHinted;
  final List<int> recentEndlessSourceLevelIds;

  int get endlessRound => endlessRoundsCompleted + 1;

  int get completedLevels => completed.length;
  bool get campaignCompleted =>
      completed.length == CampaignChapters.all.last.lastLevel &&
      completed.contains(CampaignChapters.all.last.lastLevel);

  Set<String> wordsFor(int level) => foundWords[level] ?? const <String>{};

  bool recordWord(Level level, String word) {
    if (completed.contains(level.id) ||
        !level.words.any((placement) => placement.text == word)) {
      return false;
    }
    final found = foundWords.putIfAbsent(level.id, () => <String>{});
    if (!found.add(word)) return false;
    wordsFound++;
    return true;
  }

  bool recordHint(int level) {
    if (completed.contains(level) || crystals < hintCost) return false;
    crystals -= hintCost;
    hintsUsed++;
    hintedLevels.add(level);
    return true;
  }

  bool complete(Level level) {
    if (!completed.add(level.id)) return false;
    if (!hintedLevels.contains(level.id)) {
      levelsWithoutHints++;
      currentStreak++;
      if (currentStreak > bestStreak) bestStreak = currentStreak;
    } else {
      currentStreak = 0;
    }
    crystals += 3;
    crystalsEarned += 3;
    if (level.id < CampaignChapters.all.last.lastLevel) {
      currentLevel = level.id + 1;
      pendingChapterId = CampaignChapters.afterLevel(level.id)?.id;
    } else {
      currentLevel = level.id;
      pendingChapterId = null;
    }
    return true;
  }

  void acknowledgeChapter() => pendingChapterId = null;

  int startEndless(List<Level> levels, {Random? random}) {
    if (!campaignCompleted) throw StateError('Campaign is not complete');
    if (activeEndlessSourceLevelId case final active?) return active;
    final pool = levels
        .where((level) => level.id >= 50 && level.id <= 150)
        .toList();
    if (pool.isEmpty) throw StateError('Endless pool is empty');
    final fresh = pool
        .where((level) => !recentEndlessSourceLevelIds.contains(level.id))
        .toList();
    final choices = fresh.isEmpty ? pool : fresh;
    final selected = choices[(random ?? Random()).nextInt(choices.length)].id;
    activeEndlessSourceLevelId = selected;
    endlessFoundWords.clear();
    endlessHinted = false;
    recentEndlessSourceLevelIds.add(selected);
    if (recentEndlessSourceLevelIds.length > 10) {
      recentEndlessSourceLevelIds.removeAt(0);
    }
    return selected;
  }

  bool recordEndlessWord(Level source, String word) {
    if (activeEndlessSourceLevelId != source.id ||
        !source.words.any((placement) => placement.text == word) ||
        !endlessFoundWords.add(word)) {
      return false;
    }
    wordsFound++;
    return true;
  }

  bool recordEndlessHint() {
    if (activeEndlessSourceLevelId == null || crystals < hintCost) {
      return false;
    }
    crystals -= hintCost;
    hintsUsed++;
    endlessHinted = true;
    return true;
  }

  bool completeEndless(Level source) {
    if (activeEndlessSourceLevelId != source.id ||
        endlessFoundWords.length != source.words.length) {
      return false;
    }
    endlessRoundsCompleted++;
    if (endlessHinted) {
      currentStreak = 0;
    } else {
      levelsWithoutHints++;
      currentStreak++;
      if (currentStreak > bestStreak) bestStreak = currentStreak;
    }
    crystals += 3;
    crystalsEarned += 3;
    activeEndlessSourceLevelId = null;
    endlessFoundWords.clear();
    endlessHinted = false;
    return true;
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': 2,
    'currentLevel': currentLevel,
    'completed': completed.toList()..sort(),
    'wordsFound': wordsFound,
    'hintsUsed': hintsUsed,
    'levelsWithoutHints': levelsWithoutHints,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'crystalsEarned': crystalsEarned,
    'crystals': crystals,
    'foundWords': foundWords.map(
      (id, words) => MapEntry('$id', words.toList()..sort()),
    ),
    'hintedLevels': hintedLevels.toList()..sort(),
    'unlockedAt': unlockedAt.map(
      (id, time) => MapEntry(id, time.toIso8601String()),
    ),
    'pendingChapterId': pendingChapterId,
    'seenScenes': seenScenes.toList()..sort(),
    'campaignFinalSeen': campaignFinalSeen,
    'endlessRoundsCompleted': endlessRoundsCompleted,
    'activeEndlessSourceLevelId': activeEndlessSourceLevelId,
    'endlessFoundWords': endlessFoundWords.toList()..sort(),
    'endlessHinted': endlessHinted,
    'recentEndlessSourceLevelIds': recentEndlessSourceLevelIds,
  };

  factory CampaignProgress.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 2) {
      throw const FormatException('Campaign schema');
    }
    final found = (json['foundWords'] as Map<String, dynamic>? ?? {}).map(
      (key, value) =>
          MapEntry(int.parse(key), (value as List).cast<String>().toSet()),
    );
    final unlocks = (json['unlockedAt'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, DateTime.parse(value as String)),
    );
    return CampaignProgress(
      currentLevel: json['currentLevel'] as int? ?? 1,
      completed: (json['completed'] as List? ?? []).cast<int>().toSet(),
      wordsFound: json['wordsFound'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      levelsWithoutHints: json['levelsWithoutHints'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      crystalsEarned: json['crystalsEarned'] as int? ?? 0,
      crystals: json['crystals'] as int? ?? 0,
      foundWords: found,
      hintedLevels: (json['hintedLevels'] as List? ?? []).cast<int>().toSet(),
      unlockedAt: unlocks,
      seenScenes: (json['seenScenes'] as List? ?? []).cast<String>().toSet(),
      pendingChapterId: json['pendingChapterId'] as int?,
      campaignFinalSeen: json['campaignFinalSeen'] as bool? ?? false,
      endlessRoundsCompleted: json['endlessRoundsCompleted'] as int? ?? 0,
      activeEndlessSourceLevelId: json['activeEndlessSourceLevelId'] as int?,
      endlessFoundWords: (json['endlessFoundWords'] as List? ?? [])
          .cast<String>()
          .toSet(),
      endlessHinted: json['endlessHinted'] as bool? ?? false,
      recentEndlessSourceLevelIds:
          (json['recentEndlessSourceLevelIds'] as List? ?? []).cast<int>(),
    );
  }
}
