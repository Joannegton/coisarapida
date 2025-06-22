import 'package:flutter/material.dart';
import '../../domain/entities/item.dart';

class DetalhesItemBottomBarWidget extends StatelessWidget {
  final Item item;
  final bool isCreatingChat;
  final VoidCallback? onChatPressed;
  final VoidCallback onAlugarPressed;

  const DetalhesItemBottomBarWidget({
    super.key,
    required this.isCreatingChat,
    required this.item,
    this.onChatPressed,
    required this.onAlugarPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onChatPressed,
                icon: const Icon(Icons.chat),
                label: isCreatingChat
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ) 
                  : const Text('Conversar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: item.disponivel ? onAlugarPressed : null,
                icon: const Icon(Icons.calendar_today),
                label: Text(item.disponivel ? 'Alugar Agora' : 'Indisponível'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}