import 'package:flutter/material.dart';

/// Botão customizado para login com Google
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
              'assets/images/google_logo.png',
              width: 20,
              height: 20,
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
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
    );
  }
}
