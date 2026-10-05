import 'package:flutter/material.dart';

import '../core/theme/game_theme.dart';
import '../core/widgets/pixel_ui.dart';
import '../core/widgets/scenic_background.dart';
import 'campaign_chapter.dart';

class ChapterTransitionScreen extends StatelessWidget {
  const ChapterTransitionScreen({
    super.key,
    required this.chapter,
    required this.onContinue,
  });

  final CampaignChapter chapter;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ScenicBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: PixelPanel(
                highlight: true,
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ГЛАВА ${chapter.id}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: GameColors.orange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      chapter.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Путь продолжается...'),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: PixelButton(
                        onPressed: onContinue,
                        accent: true,
                        child: const Text('ПРОДОЛЖИТЬ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
