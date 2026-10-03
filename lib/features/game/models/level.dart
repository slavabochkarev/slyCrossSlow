class WordPlacement {
  const WordPlacement({
    required this.text,
    required this.row,
    required this.col,
    required this.down,
  });

  final String text;
  final int row;
  final int col;
  final bool down;

  factory WordPlacement.fromJson(Map<String, dynamic> json) => WordPlacement(
    text: json['text'] as String,
    row: json['row'] as int,
    col: json['col'] as int,
    down: json['direction'] == 'down',
  );
}

class Level {
  const Level({required this.id, required this.letters, required this.words});

  final int id;
  final List<String> letters;
  final List<WordPlacement> words;

  int get rows => words
      .map((w) => w.row + (w.down ? w.text.length : 1))
      .reduce((a, b) => a > b ? a : b);
  int get cols => words
      .map((w) => w.col + (w.down ? 1 : w.text.length))
      .reduce((a, b) => a > b ? a : b);

  factory Level.fromJson(Map<String, dynamic> json) => Level(
    id: json['id'] as int,
    letters: (json['letters'] as List).cast<String>(),
    words: (json['words'] as List)
        .map((w) => WordPlacement.fromJson(w as Map<String, dynamic>))
        .toList(),
  );
}
