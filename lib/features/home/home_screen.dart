import 'package:flutter/material.dart';

import '../../campaign/campaign_chapter.dart';
import '../../campaign/chapter_scene.dart';
import '../../campaign/chapter_scene_backdrop.dart';
import '../../core/theme/game_theme.dart';
import '../../core/widgets/pixel_ui.dart';
import '../../core/widgets/scenic_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.level,
    required this.totalLevels,
    required this.completed,
    this.campaignCompleted = false,
    this.endlessRoundsCompleted = 0,
    this.crystals = 0,
    required this.onContinue,
    this.onMenu,
  });

  final int level;
  final int totalLevels;
  final int completed;
  final bool campaignCompleted;
  final int endlessRoundsCompleted;
  final int crystals;
  final VoidCallback onContinue;
  final ValueChanged<BuildContext>? onMenu;

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    final chapter = CampaignChapters.forLevel(level);
    final chapterPosition = campaignCompleted
        ? chapter.totalLevels
        : chapter.positionOf(level);
    final scene = ChapterScenes.forLevel(level);
    if (scene != null) {
      return _sceneHome(context, scene, chapter, chapterPosition);
    }
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
                                  const CrystalIcon(size: 22),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$crystals',
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
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: wide ? 28 : 22),
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
                                  'ПУТЕШЕСТВИЕ',
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
                                        campaignCompleted
                                            ? 'КРАЙ СВЕТА'
                                            : 'УРОВЕНЬ $level',
                                        style: TextStyle(
                                          color: palette.ink,
                                          fontSize: campaignCompleted
                                              ? 20
                                              : (wide ? 32 : 27),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        campaignCompleted
                                            ? 'Кампания пройдена'
                                            : 'Глава ${chapter.id} · ${chapter.name}',
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
                                              value:
                                                  chapterPosition /
                                                  chapter.totalLevels,
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
                                            campaignCompleted
                                                ? '$completed / $totalLevels'
                                                : '$chapterPosition / ${chapter.totalLevels}',
                                            style: TextStyle(
                                              color: palette.ink,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (campaignCompleted) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          'Бесконечная игра · $endlessRoundsCompleted',
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: wide ? 340 : 300,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 60,
                                    child: PixelButton(
                                      onPressed: onContinue,
                                      accent: true,
                                      borderRadius: 30,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            campaignCompleted
                                                ? 'ИГРАТЬ'
                                                : 'ПРОДОЛЖИТЬ',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.play_arrow_rounded,
                                            size: 29,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _sceneHome(
    BuildContext context,
    ChapterScene scene,
    CampaignChapter chapter,
    int chapterPosition,
  ) {
    final palette = GamePalette.of(context);
    const textShadow = <Shadow>[
      Shadow(color: Color(0xD9000915), blurRadius: 8, offset: Offset(0, 2)),
    ];
    final fraction = chapterPosition / chapter.totalLevels;
    return Scaffold(
      body: ChapterSceneBackdrop(
        scene: scene,
        readabilityGradient: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final wide = bounds.maxWidth >= 740;
              final horizontal = wide ? 30.0 : 20.0;
              final logoHeight = (bounds.maxHeight * .105).clamp(62.0, 92.0);
              return Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 24),
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
                              const CrystalIcon(size: 22),
                              const SizedBox(width: 6),
                              Text(
                                '$crystals',
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
                    const SizedBox(height: 10),
                    Center(
                      child: Image.asset(
                        'doc/logo.png',
                        height: logoHeight,
                        width: wide ? 300 : 260,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        semanticLabel: 'КроссСлов',
                      ),
                    ),
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            campaignCompleted
                                ? scene.title.toUpperCase()
                                : 'УРОВЕНЬ $level',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: campaignCompleted ? 20 : 30,
                              fontWeight: FontWeight.w900,
                              shadows: textShadow,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            campaignCompleted
                                ? 'Кампания пройдена'
                                : 'Глава ${chapter.id} · ${chapter.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              shadows: textShadow,
                            ),
                          ),
                          const SizedBox(height: 19),
                          Text(
                            campaignCompleted
                                ? '$completed / $totalLevels'
                                : '$chapterPosition / ${chapter.totalLevels}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              shadows: textShadow,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 16,
                            child: LayoutBuilder(
                              builder: (context, track) => Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0x8805111E),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: fraction,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: GameColors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: (track.maxWidth - 15) * fraction,
                                    child: Container(
                                      width: 15,
                                      height: 15,
                                      decoration: BoxDecoration(
                                        color: GameColors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 23),
                          if (campaignCompleted) ...[
                            Text(
                              'Бесконечная игра · $endlessRoundsCompleted',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                shadows: textShadow,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          SizedBox(
                            width: 252,
                            height: 52,
                            child: PixelButton(
                              onPressed: onContinue,
                              borderRadius: 30,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    campaignCompleted ? 'ИГРАТЬ' : 'ПРОДОЛЖИТЬ',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      letterSpacing: .6,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
