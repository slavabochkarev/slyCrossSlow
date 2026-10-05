import 'package:flutter/services.dart';

/// The generator's normalized game dictionary, loaded once for fast lookups.
class GameDictionary {
  GameDictionary._();

  static Future<Set<String>>? _cached;

  static Future<Set<String>> load() => _cached ??= rootBundle
      .loadString('assets/game_words.txt')
      .then(
        (source) => Set<String>.unmodifiable(
          source.split('\n').map(normalize).where((word) => word.isNotEmpty),
        ),
      );

  static String normalize(String word) =>
      word.trim().toUpperCase().replaceAll('Ё', 'Е');
}
