import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'campaign_progress.dart';
import 'game_profiles.dart';

class ProgressRepository {
  ProgressRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const stateKey = 'campaign_150_state_v2';
  static const profilesKey = 'game_profiles_v1';

  final SharedPreferencesAsync _preferences;

  Future<GameProfiles> loadProfiles() async {
    final profilesSource = await _preferences.getString(profilesKey);
    if (profilesSource != null) {
      try {
        return GameProfiles.fromJson(
          jsonDecode(profilesSource) as Map<String, dynamic>,
        );
      } on FormatException {
        throw const FormatException('Cannot load game profiles');
      } on TypeError {
        throw const FormatException('Cannot load game profiles');
      }
    }

    final oldSource = await _preferences.getString(stateKey);
    if (oldSource != null) {
      try {
        final old = CampaignProgress.fromJson(
          jsonDecode(oldSource) as Map<String, dynamic>,
        );
        final migrated = GameProfiles(ru: old, crystals: old.crystals);
        // One write commits the complete migration. Keep the old key as backup.
        await saveProfiles(migrated);
        return migrated;
      } on FormatException {
        throw const FormatException('Cannot migrate Russian campaign state');
      } on TypeError {
        throw const FormatException('Cannot migrate Russian campaign state');
      }
    }
    final fresh = GameProfiles();
    await saveProfiles(fresh);
    return fresh;
  }

  Future<CampaignProgress> load() async => (await loadProfiles()).ru;

  Future<void> save(CampaignProgress state) async {
    final profiles = await loadProfiles();
    profiles.ru = state;
    profiles.crystals = state.crystals;
    profiles.en.crystals = state.crystals;
    await saveProfiles(profiles);
  }

  Future<void> saveProfiles(GameProfiles profiles) =>
      saveProfilesEncoded(jsonEncode(profiles.toJson()));

  Future<void> saveProfilesEncoded(String encoded) =>
      _preferences.setString(profilesKey, encoded);
}
