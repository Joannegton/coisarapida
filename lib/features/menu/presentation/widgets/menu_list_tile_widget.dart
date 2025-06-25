import 'package:flutter/material.dart';

class MenuListTile extends StatefulWidget {
  final IconData icone;
  final String texto;
  final VoidCallback onTap;

  /// - Se for um `Text`, ele substitui os ícones.
  /// - Se for outro `Widget` (ex: `Icon`), ele é sobreposto no canto da seta e terá uma animação de pulso.
  /// - Se for `null`, apenas a seta é exibida.
  final Widget? iconeAcao;

  const MenuListTile({
    super.key,
    required this.icone,
    required this.texto,
    required this.onTap,
    this.iconeAcao,
  });

  @override
  State<MenuListTile> createState() => _MenuListTileState();
}

class _MenuListTileState extends State<MenuListTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.iconeAcao != null && widget.iconeAcao is! Text) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(widget.icone, color: colorScheme.onSurfaceVariant, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Text(widget.texto, style: theme.textTheme.bodyLarge),
            ),
            const SizedBox(width: 8),
            if (widget.iconeAcao is Text)
              widget.iconeAcao!
            else
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(Icons.chevron_right, color: colorScheme.outline),
                  if (widget.iconeAcao != null)
                    Positioned(
                      top: 6,
                      right: 4,
                      child: FadeTransition(
                        opacity: _animation,
                        child: widget.iconeAcao,
                      ),
                    ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
