import '../game_language.dart';
import 'campaign_progress.dart';

/// One persisted document keeps both campaigns and one crystal balance.
class GameProfiles {
  GameProfiles({
    CampaignProgress? ru,
    CampaignProgress? en,
    this.selectedLanguage = GameLanguage.ru,
    int? crystals,
  }) : ru = ru ?? CampaignProgress(),
       en = en ?? CampaignProgress(),
       crystals = crystals ?? ru?.crystals ?? 0 {
    _syncBalance();
  }

  CampaignProgress ru;
  CampaignProgress en;
  GameLanguage selectedLanguage;
  int crystals;

  CampaignProgress get active => profile(selectedLanguage);

  CampaignProgress profile(GameLanguage language) =>
      language == GameLanguage.ru ? ru : en;

  void captureActive() {
    crystals = active.crystals;
    _syncBalance();
  }

  void select(GameLanguage language) {
    captureActive();
    selectedLanguage = language;
  }

  void _syncBalance() {
    ru.crystals = crystals;
    en.crystals = crystals;
  }

  Map<String, Object?> toJson() {
    captureActive();
    final ruState = ru.toJson()..remove('crystals');
    final enState = en.toJson()..remove('crystals');
    return {
      'schemaVersion': 1,
      'selectedLanguage': selectedLanguage.code,
      'crystals': crystals,
      'profiles': {'ru': ruState, 'en': enState},
    };
  }

  factory GameProfiles.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Game profiles schema');
    }
    final profiles = json['profiles'] as Map<String, dynamic>;
    final crystals = json['crystals'] as int;
    CampaignProgress decode(String language) {
      final state = Map<String, dynamic>.from(
        profiles[language] as Map<String, dynamic>,
      );
      state['crystals'] = crystals;
      return CampaignProgress.fromJson(state);
    }

    return GameProfiles(
      ru: decode('ru'),
      en: decode('en'),
      selectedLanguage: GameLanguage.fromCode(
        json['selectedLanguage'] as String?,
      ),
      crystals: crystals,
    );
  }
}
