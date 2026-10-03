import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.panelTop, palette.panelBottom],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: highlight ? GameColors.orange : palette.outline,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: palette.shadow, offset: Offset(0, 5), blurRadius: 0),
          BoxShadow(
            color: palette.accent.withValues(alpha: .18),
            offset: Offset(0, 0),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}

class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.accent = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool accent;
  final EdgeInsetsGeometry padding;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    return AnimatedScale(
      scale: pressed ? .97 : 1,
      duration: const Duration(milliseconds: 90),
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onPressed == null
              ? null
              : (_) => setState(() => pressed = true),
          onTapCancel: () => setState(() => pressed = false),
          onTapUp: widget.onPressed == null
              ? null
              : (_) => setState(() => pressed = false),
          onTap: widget.onPressed,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.accent
                    ? const [Color(0xFF7DD978), Color(0xFF269264)]
                    : [palette.buttonTop, palette.buttonBottom],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.accent ? const Color(0xFFC8FF9B) : palette.accent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent
                      ? const Color(0xFF115A3D)
                      : palette.shadow,
                  offset: Offset(0, pressed ? 2 : 5),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: widget.accent
                      ? const Color(0x5548EA9F)
                      : palette.accent.withValues(alpha: .34),
                  blurRadius: 8,
                ),
              ],
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: widget.accent ? Colors.white : palette.ink,
                fontWeight: FontWeight.w900,
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: widget.accent ? Colors.white : palette.ink,
                ),
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PixelIconButton extends StatelessWidget {
  const PixelIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label ?? '',
    child: PixelButton(
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 24),
    ),
  );
}

class PixelCell extends StatelessWidget {
  const PixelCell({
    super.key,
    required this.letter,
    required this.open,
    required this.side,
    this.glowing = false,
  });

  final String letter;
  final bool open;
  final double side;
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(context);
    return AnimatedScale(
      scale: glowing ? 1.08 : 1,
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: open
                ? [palette.cellOpenTop, palette.cellOpenBottom]
                : [palette.cellClosedTop, palette.cellClosedBottom],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: open ? palette.cellOpenTop : palette.outline,
            width: 2,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0xD0061031),
              offset: Offset(2, 4),
              blurRadius: 0,
            ),
            if (glowing)
              BoxShadow(color: palette.accent, blurRadius: 12, spreadRadius: 2),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: open
              ? Text(
                  letter,
                  key: ValueKey(letter),
                  style: TextStyle(
                    color: GameColors.midnight,
                    fontSize: side * .54,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
