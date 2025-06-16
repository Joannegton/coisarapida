import 'package:flutter/material.dart';

class BotaoGoogle extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const BotaoGoogle({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Image.asset(
              'assets/images/google_logo.jpg',
              width: 30,
              height: 30,
            ),
      label: Text(
        isLoading ? 'Entrando...' : 'Continuar com Google',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha((255 * 0.3).round()),
        ),
      ),
    );
  }
}
