import 'package:flutter/material.dart';

enum ChapterAmbientKind {
  goldenDust,
  fireflies,
  driftingLeaf,
  lakeSparkles,
  lakeBirds,
  lakesideLights,
  mountainWind,
  mountainAscent,
  highAltitude,
  mountainPass,
  castleRoad,
  castleGate,
  castleCourtyard,
  castleTower,
  castleNorthGate,
  northernValley,
  icyExpanse,
  northernLights,
  lastShelter,
  worldsEdge,
}

/// Visual stops within a chapter. The active scene is derived from the level.
class ChapterScene {
  const ChapterScene({
    required this.id,
    required this.chapterId,
    required this.levelFrom,
    required this.levelTo,
    required this.title,
    required this.backgroundAsset,
    required this.focalAlignment,
    required this.ambientKind,
  });

  final String id;
  final int chapterId;
  final int levelFrom;
  final int levelTo;
  final String title;
  final String backgroundAsset;
  final Alignment focalAlignment;
  final ChapterAmbientKind ambientKind;

  bool contains(int level) => levelFrom <= level && level <= levelTo;
}

class ChapterScenes {
  ChapterScenes._();

  static const all = <ChapterScene>[
    ChapterScene(
      id: 'forest_01',
      chapterId: 1,
      levelFrom: 1,
      levelTo: 7,
      title: 'Лесная опушка',
      backgroundAsset: 'assets/backgrounds/forest_01.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.goldenDust,
    ),
    ChapterScene(
      id: 'forest_02',
      chapterId: 1,
      levelFrom: 8,
      levelTo: 14,
      title: 'Глубокий лес',
      backgroundAsset: 'assets/backgrounds/forest_02.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.fireflies,
    ),
    ChapterScene(
      id: 'forest_03',
      chapterId: 1,
      levelFrom: 15,
      levelTo: 20,
      title: 'Край леса',
      backgroundAsset: 'assets/backgrounds/forest_03.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.driftingLeaf,
    ),
    ChapterScene(
      id: 'lake_01',
      chapterId: 2,
      levelFrom: 21,
      levelTo: 27,
      title: 'Берег озера',
      backgroundAsset: 'assets/backgrounds/lake_01.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.lakeSparkles,
    ),
    ChapterScene(
      id: 'lake_02',
      chapterId: 2,
      levelFrom: 28,
      levelTo: 34,
      title: 'Вдоль озера',
      backgroundAsset: 'assets/backgrounds/lake_02.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.lakeBirds,
    ),
    ChapterScene(
      id: 'lake_03',
      chapterId: 2,
      levelFrom: 35,
      levelTo: 42,
      title: 'Поселение у воды',
      backgroundAsset: 'assets/backgrounds/lake_03.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.lakesideLights,
    ),
    ChapterScene(
      id: 'lake_04',
      chapterId: 2,
      levelFrom: 43,
      levelTo: 50,
      title: 'Путь к горам',
      backgroundAsset: 'assets/backgrounds/lake_04.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.mountainWind,
    ),
    ChapterScene(
      id: 'mountains_01',
      chapterId: 3,
      levelFrom: 51,
      levelTo: 57,
      title: 'Начало подъёма',
      backgroundAsset: 'assets/backgrounds/mountains_01.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.mountainAscent,
    ),
    ChapterScene(
      id: 'mountains_02',
      chapterId: 3,
      levelFrom: 58,
      levelTo: 64,
      title: 'Высокогорье',
      backgroundAsset: 'assets/backgrounds/mountains_02.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.highAltitude,
    ),
    ChapterScene(
      id: 'mountains_03',
      chapterId: 3,
      levelFrom: 65,
      levelTo: 72,
      title: 'Горный перевал',
      backgroundAsset: 'assets/backgrounds/mountains_03.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.mountainPass,
    ),
    ChapterScene(
      id: 'mountains_04',
      chapterId: 3,
      levelFrom: 73,
      levelTo: 80,
      title: 'Дорога к замку',
      backgroundAsset: 'assets/backgrounds/mountains_04.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.castleRoad,
    ),
    ChapterScene(
      id: 'castle_01',
      chapterId: 4,
      levelFrom: 81,
      levelTo: 87,
      title: 'У ворот',
      backgroundAsset: 'assets/backgrounds/castle_01.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.castleGate,
    ),
    ChapterScene(
      id: 'castle_02',
      chapterId: 4,
      levelFrom: 88,
      levelTo: 94,
      title: 'Старый двор',
      backgroundAsset: 'assets/backgrounds/castle_02.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.castleCourtyard,
    ),
    ChapterScene(
      id: 'castle_03',
      chapterId: 4,
      levelFrom: 95,
      levelTo: 102,
      title: 'Высокая башня',
      backgroundAsset: 'assets/backgrounds/castle_03.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.castleTower,
    ),
    ChapterScene(
      id: 'castle_04',
      chapterId: 4,
      levelFrom: 103,
      levelTo: 110,
      title: 'Северные ворота',
      backgroundAsset: 'assets/backgrounds/castle_04.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.castleNorthGate,
    ),
    ChapterScene(
      id: 'north_01',
      chapterId: 5,
      levelFrom: 111,
      levelTo: 118,
      title: 'Северная долина',
      backgroundAsset: 'assets/backgrounds/north_01.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.northernValley,
    ),
    ChapterScene(
      id: 'north_02',
      chapterId: 5,
      levelFrom: 119,
      levelTo: 126,
      title: 'Ледяные просторы',
      backgroundAsset: 'assets/backgrounds/north_02.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.icyExpanse,
    ),
    ChapterScene(
      id: 'north_03',
      chapterId: 5,
      levelFrom: 127,
      levelTo: 134,
      title: 'Северное сияние',
      backgroundAsset: 'assets/backgrounds/north_03.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.northernLights,
    ),
    ChapterScene(
      id: 'north_04',
      chapterId: 5,
      levelFrom: 135,
      levelTo: 142,
      title: 'Последний приют',
      backgroundAsset: 'assets/backgrounds/north_04.webp',
      focalAlignment: Alignment.center,
      ambientKind: ChapterAmbientKind.lastShelter,
    ),
    ChapterScene(
      id: 'north_05',
      chapterId: 5,
      levelFrom: 143,
      levelTo: 150,
      title: 'Край света',
      backgroundAsset: 'assets/backgrounds/north_05.webp',
      focalAlignment: Alignment(0, -.55),
      ambientKind: ChapterAmbientKind.worldsEdge,
    ),
  ];

  static ChapterScene? forLevel(int level) {
    for (final scene in all) {
      if (scene.contains(level)) return scene;
    }
    return null;
  }

  static ChapterScene? openingForLevel(int level) {
    final scene = forLevel(level);
    return scene?.levelFrom == level ? scene : null;
  }

  static ChapterScene? unseenOpeningForLevel(
    int level,
    Set<String> seenScenes,
  ) {
    final scene = openingForLevel(level);
    return scene != null && !seenScenes.contains(scene.id) ? scene : null;
  }
}
