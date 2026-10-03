import 'package:flutter/material.dart';

import '../../core/theme/game_theme.dart';
import '../../core/widgets/pixel_ui.dart';
import '../../core/widgets/scenic_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.level,
    required this.totalLevels,
    required this.completed,
    required this.onContinue,
    this.onMenu,
  });

  final int level;
  final int totalLevels;
  final int completed;
  final VoidCallback onContinue;
  final ValueChanged<BuildContext>? onMenu;

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    return Scaffold(
      body: ScenicBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final wide = bounds.maxWidth >= 740;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 30 : 20,
                      vertical: 14,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            PixelIconButton(
                              icon: Icons.menu_rounded,
                              label: 'Меню',
                              onPressed: () => onMenu?.call(context),
                            ),
                            const Spacer(),
                            PixelPanel(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.diamond,
                                    color: Color(0xFFE990FF),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '0',
                                    style: TextStyle(
                                      color: palette.ink,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: wide ? 440 : 310,
                                  ),
                                  child: Image.asset(
                                    'doc/logo.png',
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.none,
                                    semanticLabel: 'КроссСлов',
                                  ),
                                ),
                                SizedBox(height: wide ? 26 : 20),
                                Text(
                                  'ЛЕСНОЙ ПУТЬ',
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontSize: wide ? 19 : 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: palette.shadow,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: wide ? 20 : 14),
                                PixelPanel(
                                  padding: const EdgeInsets.fromLTRB(
                                    22,
                                    18,
                                    22,
                                    20,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'УРОВЕНЬ $level',
                                        style: TextStyle(
                                          color: palette.ink,
                                          fontSize: wide ? 32 : 27,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Глава 1 · Лес',
                                        style: TextStyle(
                                          color: palette.muted,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: totalLevels == 0
                                                  ? 0
                                                  : completed / totalLevels,
                                              minHeight: 13,
                                              backgroundColor: palette.board,
                                              valueColor:
                                                  const AlwaysStoppedAnimation(
                                                    GameColors.orange,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '$completed / $totalLevels',
                                            style: TextStyle(
                                              color: palette.ink,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: PixelButton(
                            onPressed: onContinue,
                            accent: true,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ПРОДОЛЖИТЬ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.play_arrow_rounded, size: 29),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
