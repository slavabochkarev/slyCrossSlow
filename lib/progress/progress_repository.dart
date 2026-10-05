import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'campaign_progress.dart';

class ProgressRepository {
  ProgressRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const stateKey = 'campaign_150_state_v2';
  static const _legacyKeys = <String>[
    'current_level',
    'completed_levels',
    'crystal_balance',
  ];

  final SharedPreferencesAsync _preferences;

  Future<CampaignProgress> load() async {
    final source = await _preferences.getString(stateKey);
    if (source != null) {
      try {
        return CampaignProgress.fromJson(
          jsonDecode(source) as Map<String, dynamic>,
        );
      } on FormatException {
        // A malformed or unknown campaign schema starts a clean campaign.
      } on TypeError {
        // Treat malformed local state the same way as an unknown schema.
      }
    }
    final fresh = CampaignProgress();
    // Save first so a crash during legacy cleanup cannot revive test progress.
    await save(fresh);
    for (final key in _legacyKeys) {
      await _preferences.remove(key);
    }
    return fresh;
  }

  Future<void> save(CampaignProgress state) =>
      saveEncoded(jsonEncode(state.toJson()));

  Future<void> saveEncoded(String encoded) =>
      _preferences.setString(stateKey, encoded);
}
