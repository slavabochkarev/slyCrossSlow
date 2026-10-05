import 'dart:async';

import 'package:flutter/material.dart';

import '../core/widgets/pixel_ui.dart';
import 'chapter_scene.dart';
import 'chapter_scene_backdrop.dart';

/// The first visit to a scene briefly gives the image the full screen.
class ChapterSceneRevealScreen extends StatefulWidget {
  const ChapterSceneRevealScreen({
    super.key,
    required this.scene,
    required this.onContinue,
    this.title,
    this.subtitle,
    this.caption,
    this.buttonLabel = 'ПРОДОЛЖИТЬ',
  });

  final ChapterScene scene;
  final VoidCallback onContinue;
  final String? title;
  final String? subtitle;
  final String? caption;
  final String buttonLabel;

  @override
  State<ChapterSceneRevealScreen> createState() =>
      _ChapterSceneRevealScreenState();
}

class _ChapterSceneRevealScreenState extends State<ChapterSceneRevealScreen> {
  Timer? revealTimer;
  bool showControls = false;

  @override
  void initState() {
    super.initState();
    revealTimer = Timer(const Duration(milliseconds: 1250), () {
      if (mounted) setState(() => showControls = true);
    });
  }

  @override
  void dispose() {
    revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ChapterSceneBackdrop(
      scene: widget.scene,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
          child: AnimatedOpacity(
            opacity: showControls ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 550),
            child: IgnorePointer(
              ignoring: !showControls,
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    widget.title ?? widget.scene.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: Color(0xE0000912),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (widget.subtitle case final subtitle?) ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                    ),
                  ],
                  if (widget.caption case final caption?) ...[
                    const SizedBox(height: 8),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                    ),
                  ],
                  const SizedBox(height: 25),
                  SizedBox(
                    width: 236,
                    height: 52,
                    child: PixelButton(
                      onPressed: widget.onContinue,
                      borderRadius: 30,
                      child: Text(
                        widget.buttonLabel,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
