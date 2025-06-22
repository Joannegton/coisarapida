import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SemConversasWidget extends StatelessWidget {
  const SemConversasWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: theme.colorScheme.onSurface.withAlpha(102),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma conversa ainda',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Quando você entrar em contato com alguém sobre um item, suas conversas aparecerão aqui.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.buscar),
              icon: const Icon(Icons.search),
              label: const Text('Explorar Itens'),
            ),
          ],
        ), 
      ),
    );
  }
}