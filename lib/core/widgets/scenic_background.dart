import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// A standalone scenery layer, independent from each screen's controls.
class ScenicBackground extends StatelessWidget {
  const ScenicBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final palette = GamePalette.of(context);
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            wide
                ? 'assets/backgrounds/forest_wide.png'
                : 'assets/backgrounds/forest_portrait.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? const [
                        Color(0x9B071331),
                        Color(0x33071331),
                        Color(0x44071331),
                        Color(0xB8071331),
                      ]
                    : [
                        palette.scrim,
                        palette.scrim.withValues(alpha: .18),
                        palette.scrim.withValues(alpha: .25),
                        palette.scrim,
                      ],
                stops: [0, .34, .65, 1],
              ),
            ),
          ),
          child,
        ],
      );
    },
  );
}
