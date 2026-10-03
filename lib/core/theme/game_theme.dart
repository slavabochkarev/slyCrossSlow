import 'package:flutter/material.dart';

class GameColors {
  static const midnight = Color(0xFF071331);
  static const blue = Color(0xFF12295A);
  static const cyan = Color(0xFF64E4FF);
  static const orange = Color(0xFFFFBB63);
  static const cream = Color(0xFFFFF4D7);
}

class GamePalette extends ThemeExtension<GamePalette> {
  const GamePalette({
    required this.panelTop,
    required this.panelBottom,
    required this.outline,
    required this.shadow,
    required this.buttonTop,
    required this.buttonBottom,
    required this.cellClosedTop,
    required this.cellClosedBottom,
    required this.cellOpenTop,
    required this.cellOpenBottom,
    required this.board,
    required this.ink,
    required this.accent,
    required this.muted,
    required this.scrim,
  });

  final Color panelTop, panelBottom, outline, shadow;
  final Color buttonTop, buttonBottom, cellClosedTop, cellClosedBottom;
  final Color cellOpenTop, cellOpenBottom, board, ink, accent, muted, scrim;

  static const dark = GamePalette(
    panelTop: Color(0xEE203B77),
    panelBottom: Color(0xF009173E),
    outline: Color(0xFF5D92C7),
    shadow: Color(0xFF03102C),
    buttonTop: Color(0xFF2C5CA0),
    buttonBottom: Color(0xFF102B65),
    cellClosedTop: Color(0xDF314D83),
    cellClosedBottom: Color(0xE9142653),
    cellOpenTop: Colors.white,
    cellOpenBottom: Color(0xFFBFDDF5),
    board: Color(0xCC061331),
    ink: Colors.white,
    accent: GameColors.cyan,
    muted: Color(0xFFCCE4FF),
    scrim: Color(0xB8071331),
  );

  static const light = GamePalette(
    panelTop: Color(0xF8FFF7E9),
    panelBottom: Color(0xF5BBDDF4),
    outline: Color(0xFF32749E),
    shadow: Color(0xFF1B4667),
    buttonTop: Color(0xFFE6F7FF),
    buttonBottom: Color(0xFF89C9E9),
    cellClosedTop: Color(0xFDD4E8F6),
    cellClosedBottom: Color(0xFF84B6DA),
    cellOpenTop: Color(0xFFFFFBEA),
    cellOpenBottom: Color(0xFFE4F5FC),
    board: Color(0xE8D3EAF9),
    ink: Color(0xFF102D51),
    accent: Color(0xFF00749B),
    muted: Color(0xFF315E7C),
    scrim: Color(0x88EAF7FF),
  );

  static GamePalette of(BuildContext context) =>
      Theme.of(context).extension<GamePalette>() ?? dark;

  @override
  GamePalette copyWith({
    Color? panelTop,
    Color? panelBottom,
    Color? outline,
    Color? shadow,
    Color? buttonTop,
    Color? buttonBottom,
    Color? cellClosedTop,
    Color? cellClosedBottom,
    Color? cellOpenTop,
    Color? cellOpenBottom,
    Color? board,
    Color? ink,
    Color? accent,
    Color? muted,
    Color? scrim,
  }) => GamePalette(
    panelTop: panelTop ?? this.panelTop,
    panelBottom: panelBottom ?? this.panelBottom,
    outline: outline ?? this.outline,
    shadow: shadow ?? this.shadow,
    buttonTop: buttonTop ?? this.buttonTop,
    buttonBottom: buttonBottom ?? this.buttonBottom,
    cellClosedTop: cellClosedTop ?? this.cellClosedTop,
    cellClosedBottom: cellClosedBottom ?? this.cellClosedBottom,
    cellOpenTop: cellOpenTop ?? this.cellOpenTop,
    cellOpenBottom: cellOpenBottom ?? this.cellOpenBottom,
    board: board ?? this.board,
    ink: ink ?? this.ink,
    accent: accent ?? this.accent,
    muted: muted ?? this.muted,
    scrim: scrim ?? this.scrim,
  );

  @override
  GamePalette lerp(ThemeExtension<GamePalette>? other, double t) {
    if (other is! GamePalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return GamePalette(
      panelTop: mix(panelTop, other.panelTop),
      panelBottom: mix(panelBottom, other.panelBottom),
      outline: mix(outline, other.outline),
      shadow: mix(shadow, other.shadow),
      buttonTop: mix(buttonTop, other.buttonTop),
      buttonBottom: mix(buttonBottom, other.buttonBottom),
      cellClosedTop: mix(cellClosedTop, other.cellClosedTop),
      cellClosedBottom: mix(cellClosedBottom, other.cellClosedBottom),
      cellOpenTop: mix(cellOpenTop, other.cellOpenTop),
      cellOpenBottom: mix(cellOpenBottom, other.cellOpenBottom),
      board: mix(board, other.board),
      ink: mix(ink, other.ink),
      accent: mix(accent, other.accent),
      muted: mix(muted, other.muted),
      scrim: mix(scrim, other.scrim),
    );
  }
}

class GameTheme {
  static ThemeData get data => dark;
  static ThemeData get dark => _build(GamePalette.dark, Brightness.dark);
  static ThemeData get light => _build(GamePalette.light, Brightness.light);

  static ThemeData _build(GamePalette palette, Brightness brightness) =>
      ThemeData(
        useMaterial3: true,
        brightness: brightness,
        scaffoldBackgroundColor: brightness == Brightness.dark
            ? GameColors.midnight
            : const Color(0xFFEAF6FE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.accent,
          brightness: brightness,
          surface: palette.panelBottom,
          onSurface: palette.ink,
        ),
        extensions: [palette],
        appBarTheme: AppBarTheme(
          backgroundColor: palette.panelBottom,
          foregroundColor: palette.ink,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          headlineMedium: TextStyle(fontWeight: FontWeight.w900),
          titleLarge: TextStyle(fontWeight: FontWeight.w800),
          bodyLarge: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
}
