import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/level.dart';
import '../data/game_dictionary.dart';

enum WordResult { correct, alreadyFound, validNotInCrossword, unknown }

class GameController extends ChangeNotifier {
  GameController(
    this.level, {
    Random? random,
    Set<String> dictionary = const {},
    Set<String> initialFound = const {},
  }) : _random = random ?? Random(),
       // The public parameter keeps the dictionary injectable for tests.
       // ignore: prefer_initializing_formals
       _dictionary = dictionary,
       found = {...initialFound};

  final Level level;
  final Random _random;
  Set<String> _dictionary;
  final Set<String> found;
  final Set<String> revealed = {};

  bool get completed => found.length == level.words.length;

  bool get canRevealOne => _closedCells().isNotEmpty;

  void setDictionary(Set<String> words) => _dictionary = words;

  bool _canCompose(String word) {
    final remaining = level.letters.map(GameDictionary.normalize).toList();
    for (final letter in word.split('')) {
      if (!remaining.remove(letter)) return false;
    }
    return true;
  }

  WordResult submit(String word) {
    final normalized = GameDictionary.normalize(word);
    if (found.contains(normalized)) return WordResult.alreadyFound;
    if (!level.words.any((placement) => placement.text == normalized)) {
      return _canCompose(normalized) && _dictionary.contains(normalized)
          ? WordResult.validNotInCrossword
          : WordResult.unknown;
    }
    found.add(normalized);
    notifyListeners();
    return WordResult.correct;
  }

  List<String> _closedCells() {
    final cells = <String>{};
    final alreadyVisible = <String>{...revealed};
    for (final placement in level.words) {
      for (var index = 0; index < placement.text.length; index++) {
        final key =
            '${placement.row + (placement.down ? index : 0)}:${placement.col + (placement.down ? 0 : index)}';
        cells.add(key);
        if (found.contains(placement.text)) alreadyVisible.add(key);
      }
    }
    return cells.difference(alreadyVisible).toList();
  }

  bool revealOne() {
    final closed = _closedCells();
    if (closed.isEmpty) return false;
    revealed.add(closed[_random.nextInt(closed.length)]);
    notifyListeners();
    return true;
  }
}
