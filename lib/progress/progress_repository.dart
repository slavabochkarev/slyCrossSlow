import 'package:shared_preferences/shared_preferences.dart';

class SavedProgress {
  const SavedProgress(this.currentLevel, this.completed);
  final int currentLevel;
  final Set<int> completed;
}

class ProgressRepository {
  final _preferences = SharedPreferencesAsync();

  Future<SavedProgress> load() async {
    final current = await _preferences.getInt('current_level') ?? 1;
    final ids = await _preferences.getStringList('completed_levels') ?? [];
    return SavedProgress(current, ids.map(int.parse).toSet());
  }

  Future<void> save(int currentLevel, Set<int> completed) async {
    await _preferences.setInt('current_level', currentLevel);
    await _preferences.setStringList(
      'completed_levels',
      completed.map((id) => '$id').toList(),
    );
  }
}
