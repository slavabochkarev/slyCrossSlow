import 'package:flutter/services.dart';

import '../../../game_language.dart';

/// The generator's normalized game dictionary, loaded once for fast lookups.
class GameDictionary {
  GameDictionary._();

  static final RegExp _englishLetters = RegExp(r'^[A-Z]+$');
  static final RegExp _englishWord = RegExp(r'^[A-Z]{3,7}$');
  static final Map<GameLanguage, Future<Set<String>>> _cached = {};

  static Future<Set<String>> load([GameLanguage language = GameLanguage.ru]) =>
      _cached.putIfAbsent(
        language,
        () => rootBundle
            .loadString(
              language == GameLanguage.ru
                  ? 'assets/game_words.txt'
                  : 'assets/recognition_words_en.txt',
            )
            .then(
              (source) => Set<String>.unmodifiable(
                source
                    .split(RegExp(r'\r?\n'))
                    .map((word) => normalize(word, language))
                    .where(
                      (word) => language == GameLanguage.ru
                          ? word.isNotEmpty
                          : _englishWord.hasMatch(word),
                    ),
              ),
            ),
      );

  static Future<Set<String>> loadGameWords(GameLanguage language) async {
    if (language == GameLanguage.ru) return load(language);
    final source = await rootBundle.loadString('assets/game_words_en.txt');
    return Set<String>.unmodifiable(
      source.split(RegExp(r'\r?\n')).where(_englishWord.hasMatch),
    );
  }

  static String normalize(
    String word, [
    GameLanguage language = GameLanguage.ru,
  ]) {
    final normalized = word.trim().toUpperCase();
    return language == GameLanguage.ru
        ? normalized.replaceAll('Ё', 'Е')
        : (_englishLetters.hasMatch(normalized) ? normalized : '');
  }
}
