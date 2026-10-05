import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/game_theme.dart';
import '../../core/widgets/pixel_ui.dart';
import '../../core/widgets/scenic_background.dart';
import '../../features/game/models/level.dart';
import '../../progress/achievements.dart';
import '../../progress/campaign_progress.dart';
import 'info_content.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.progress,
    required this.levels,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final CampaignProgress progress;
  final List<Level> levels;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late ThemeMode selectedTheme = widget.themeMode;

  void _selectTheme(ThemeMode mode) {
    setState(() => selectedTheme = mode);
    widget.onThemeChanged(mode);
  }

  void _open(InfoDocument document) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _InfoDocumentScreen(document: document),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('МЕНЮ'),
          bottom: TabBar(
            indicatorColor: palette.accent,
            labelColor: palette.ink,
            unselectedLabelColor: palette.muted,
            labelStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
            tabs: const [
              Tab(text: 'ИГРА'),
              Tab(text: 'ИНФО'),
            ],
          ),
        ),
        body: ScenicBackground(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: TabBarView(
                children: [_gameTab(palette), _infoTab(palette)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameTab(GamePalette palette) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _sectionTitle('ТЕМА', palette),
      const SizedBox(height: 10),
      PixelPanel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _themeRow(
              'Тёмная',
              Icons.dark_mode_outlined,
              ThemeMode.dark,
              palette,
            ),
            Divider(height: 1, color: palette.outline),
            _themeRow(
              'Светлая',
              Icons.light_mode_outlined,
              ThemeMode.light,
              palette,
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      _sectionTitle('ПРОГРЕСС', palette),
      const SizedBox(height: 10),
      _row(
        'Статистика',
        Icons.bar_chart_rounded,
        palette,
        () => _showStatistics(),
      ),
      const SizedBox(height: 12),
      _row(
        'Достижения',
        Icons.emoji_events_outlined,
        palette,
        () => _showAchievements(),
      ),
    ],
  );

  Widget _themeRow(
    String title,
    IconData icon,
    ThemeMode mode,
    GamePalette palette,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
    leading: Icon(icon, color: palette.accent, size: 28),
    title: Text(
      title,
      style: TextStyle(
        color: palette.ink,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    trailing: Icon(
      selectedTheme == mode
          ? Icons.radio_button_checked
          : Icons.radio_button_unchecked,
      color: palette.accent,
      size: 26,
    ),
    onTap: () => _selectTheme(mode),
  );

  Widget _infoTab(GamePalette palette) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _row(
        'Об игре',
        Icons.menu_book_outlined,
        palette,
        () => _open(aboutDocument),
      ),
      const SizedBox(height: 12),
      _row(
        'Как играть',
        Icons.help_outline_rounded,
        palette,
        () => _open(howToDocument),
      ),
      const SizedBox(height: 12),
      _row(
        'Политика конфиденциальности',
        Icons.privacy_tip_outlined,
        palette,
        () => _open(privacyDocument),
      ),
      const SizedBox(height: 12),
      _row(
        'Пользовательское соглашение',
        Icons.description_outlined,
        palette,
        () => _open(termsDocument),
      ),
      const SizedBox(height: 12),
      _row(
        'Обратная связь',
        Icons.mail_outline,
        palette,
        () => _open(feedbackDocument),
      ),
      const SizedBox(height: 28),
      FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) => Text(
          snapshot.hasData
              ? 'КроссСлов · версия ${snapshot.data!.version}'
              : 'КроссСлов · версия недоступна',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, fontSize: 14),
        ),
      ),
    ],
  );

  Widget _sectionTitle(String title, GamePalette palette) => Text(
    title,
    style: TextStyle(
      color: palette.ink,
      fontSize: 17,
      fontWeight: FontWeight.w900,
      letterSpacing: 1,
    ),
  );

  Widget _row(
    String title,
    IconData icon,
    GamePalette palette,
    VoidCallback action,
  ) => PixelPanel(
    padding: EdgeInsets.zero,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Icon(icon, color: palette.accent, size: 29),
      title: Text(
        title,
        style: TextStyle(
          color: palette.ink,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: palette.muted),
      onTap: action,
    ),
  );

  void _showStatistics() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _DetailScreen(
        title: 'Статистика',
        children: [
          _stat(
            'Пройдено уровней',
            '${widget.progress.completedLevels} / ${widget.levels.length}',
          ),
          _stat('Найдено слов', '${widget.progress.wordsFound}'),
          _stat(
            'Бесконечные раунды',
            '${widget.progress.endlessRoundsCompleted}',
          ),
          _stat('Без подсказок', '${widget.progress.levelsWithoutHints}'),
          _stat('Использовано подсказок', '${widget.progress.hintsUsed}'),
          _stat('Текущая серия', '${widget.progress.currentStreak}'),
          _stat('Лучшая серия', '${widget.progress.bestStreak}'),
          _stat('Заработано кристаллов', '${widget.progress.crystalsEarned}'),
        ],
      ),
    ),
  );

  void _showAchievements() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _DetailScreen(
        title: 'Достижения',
        children: [
          for (final category
              in AchievementRules.all.map((a) => a.category).toSet()) ...[
            Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _sectionTitle(
                  category.toUpperCase(),
                  GamePalette.of(context),
                ),
              ),
            ),
            for (final achievement in AchievementRules.all.where(
              (a) => a.category == category,
            ))
              _achievement(
                achievement.title,
                achievement.description,
                achievement.isUnlocked(widget.progress),
                progress: achievement.progress(widget.progress, widget.levels),
                target: achievement.target,
                chapterName: achievement.chapter?.name,
              ),
          ],
        ],
      ),
    ),
  );

  Widget _stat(String label, String value) => Builder(
    builder: (context) {
      final palette = GamePalette.of(context);
      return PixelPanel(
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: palette.ink, fontSize: 17),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: palette.accent,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _achievement(
    String title,
    String description,
    bool unlocked, {
    required int progress,
    required int target,
    String? chapterName,
  }) => Builder(
    builder: (context) {
      final palette = GamePalette.of(context);
      return PixelPanel(
        highlight: unlocked,
        child: ListTile(
          leading: Icon(
            unlocked ? Icons.emoji_events_rounded : Icons.lock_outline,
            color: unlocked ? GameColors.orange : palette.muted,
            size: 30,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: palette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            unlocked
                ? description
                : '$description\n${chapterName == null ? '' : '$chapterName: '}${progress.clamp(0, target)} / $target',
            style: TextStyle(color: palette.muted),
          ),
          trailing: unlocked
              ? const Icon(Icons.check_circle, color: GameColors.orange)
              : null,
        ),
      );
    },
  );
}

class _DetailScreen extends StatelessWidget {
  const _DetailScreen({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ScenicBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => children[index],
          ),
        ),
      ),
    ),
  );
}

class _InfoDocumentScreen extends StatelessWidget {
  const _InfoDocumentScreen({required this.document});
  final InfoDocument document;

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ScenicBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SelectionArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final section in document.sections) ...[
                    PixelPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (section.title.isNotEmpty) ...[
                            Text(
                              section.title,
                              style: TextStyle(
                                color: palette.accent,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            section.text,
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 17,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (document == feedbackDocument) const _ContactLinks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactLinks extends StatelessWidget {
  const _ContactLinks();

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // The copy action below remains available if no external app can open.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть приложение. Скопируйте контакт.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            developerName,
            style: TextStyle(
              color: palette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _contact(
            context,
            developerEmail,
            Uri(scheme: 'mailto', path: developerEmail),
            Icons.mail_outline,
          ),
          _contact(
            context,
            developerTelegram,
            Uri.parse('https://t.me/slavabochkarev'),
            Icons.send_outlined,
          ),
        ],
      ),
    );
  }

  Widget _contact(BuildContext context, String label, Uri uri, IconData icon) =>
      Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => _open(context, uri),
              icon: Icon(icon, size: 24),
              label: Text(label, style: const TextStyle(fontSize: 16)),
            ),
          ),
          IconButton(
            tooltip: 'Скопировать $label',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: label));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Контакт скопирован')),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      );
}
