import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/level.dart';
import '../../../game_language.dart';
import 'game_dictionary.dart';

class LevelRepository {
  static const bool englishCampaignIncluded = true;

  Future<List<Level>> load([GameLanguage language = GameLanguage.ru]) async {
    final source = await rootBundle.loadString(
      language == GameLanguage.ru
          ? 'assets/levels.json'
          : 'assets/levels_en.json',
    );
    return (jsonDecode(source) as List)
        .map((item) => Level.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> hasCampaign(GameLanguage language) async {
    try {
      final levels = await load(language);
      if (levels.length != 150) return false;
      if (language == GameLanguage.ru) return true;
      final gameWords = await GameDictionary.loadGameWords(language);
      final validWord = RegExp(r'^[A-Z]{3,7}$');
      final validLetter = RegExp(r'^[A-Z]$');
      return levels.asMap().entries.every((entry) {
        final level = entry.value;
        if (level.id != entry.key + 1 ||
            level.words.isEmpty ||
            level.letters.length < 3 ||
            level.letters.length > 7 ||
            level.letters.any((letter) => !validLetter.hasMatch(letter))) {
          return false;
        }
        final available = <String, int>{};
        for (final letter in level.letters) {
          available[letter] = (available[letter] ?? 0) + 1;
        }
        return level.words.every((placement) {
          final word = placement.text;
          if (!validWord.hasMatch(word) || !gameWords.contains(word)) {
            return false;
          }
          final remaining = Map<String, int>.from(available);
          for (final letter in word.split('')) {
            final count = remaining[letter] ?? 0;
            if (count == 0) return false;
            remaining[letter] = count - 1;
          }
          return true;
        });
      });
    } on Object {
      return false;
    }
  }
}
