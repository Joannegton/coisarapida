import 'package:flutter/material.dart';
import '../../domain/entities/item.dart';

class ProprietarioCardWidget extends StatelessWidget {
  final Item item;
  final VoidCallback? onChatPressed;

  const ProprietarioCardWidget({
    super.key,
    required this.item,
    this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              // TODO: Adicionar foto do proprietário ao Item/Usuario (ex: item.proprietarioFotoUrl)
              // backgroundImage: item.proprietarioFotoUrl != null && item.proprietarioFotoUrl!.isNotEmpty
              //     ? NetworkImage(item.proprietarioFotoUrl!)
              //     : null,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: /* item.proprietarioFotoUrl != null && item.proprietarioFotoUrl!.isNotEmpty
                  ? null
                  : */ Text(
                      item.proprietarioNome.isNotEmpty ? item.proprietarioNome[0].toUpperCase() : 'P',
                      style: TextStyle(fontSize: 24, color: theme.colorScheme.onSecondaryContainer),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.proprietarioNome,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(item.proprietarioReputacao?.toStringAsFixed(1) ?? 'N/A'),
                      const SizedBox(width: 16),
                      const Icon(Icons.handshake, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      // TODO: Adicionar total de alugueis do proprietario
                      const Text('0 aluguéis'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: onChatPressed,
                  icon: const Icon(Icons.chat),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
                const Text('Chat', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}