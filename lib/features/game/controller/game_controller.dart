import 'package:flutter/foundation.dart';

import '../models/level.dart';

enum WordResult { correct, alreadyFound, unknown }

class GameController extends ChangeNotifier {
  GameController(this.level);

  final Level level;
  final Set<String> found = {};
  final Set<String> revealed = {};

  bool get completed => found.length == level.words.length;

  WordResult submit(String word) {
    if (found.contains(word)) return WordResult.alreadyFound;
    if (!level.words.any((placement) => placement.text == word)) {
      return WordResult.unknown;
    }
    found.add(word);
    notifyListeners();
    return WordResult.correct;
  }

  bool revealOne() {
    final alreadyVisible = <String>{...revealed};
    for (final placement in level.words) {
      if (!found.contains(placement.text)) continue;
      for (var index = 0; index < placement.text.length; index++) {
        alreadyVisible.add(
          '${placement.row + (placement.down ? index : 0)}:${placement.col + (placement.down ? 0 : index)}',
        );
      }
    }
    for (final placement in level.words) {
      for (var index = 0; index < placement.text.length; index++) {
        final row = placement.row + (placement.down ? index : 0);
        final col = placement.col + (placement.down ? 0 : index);
        final key = '$row:$col';
        if (!found.contains(placement.text) && !alreadyVisible.contains(key)) {
          revealed.add(key);
          notifyListeners();
          return true;
        }
      }
    }
    return false;
  }
}
