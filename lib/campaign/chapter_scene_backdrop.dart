import 'package:flutter/material.dart';

import 'chapter_ambient_effects.dart';
import 'chapter_scene.dart';

class ChapterSceneBackdrop extends StatelessWidget {
  const ChapterSceneBackdrop({
    super.key,
    required this.scene,
    required this.child,
    this.readabilityGradient = false,
    this.ambientEffects = true,
  });

  final ChapterScene scene;
  final Widget child;
  final bool readabilityGradient;
  final bool ambientEffects;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        scene.backgroundAsset,
        fit: BoxFit.cover,
        alignment: scene.focalAlignment,
        filterQuality: FilterQuality.medium,
      ),
      if (ambientEffects)
        ChapterAmbientEffects(key: ValueKey(scene.id), scene: scene),
      if (readabilityGradient)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .57, .78, 1],
              colors: [
                Colors.transparent,
                Colors.transparent,
                Color(0x3005101E),
                Color(0xA80A1320),
              ],
            ),
          ),
        ),
      child,
    ],
  );
}
