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
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.035),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(widget.icone, color: colorScheme.onSurfaceVariant, size: screenWidth * 0.06),
            SizedBox(width: screenWidth * 0.05),
            Expanded(
              child: Text(widget.texto, style: theme.textTheme.bodyLarge),
            ),
            SizedBox(width: screenWidth * 0.02),
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
                      top: screenWidth * 0.015,
                      right: screenWidth * 0.01,
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
