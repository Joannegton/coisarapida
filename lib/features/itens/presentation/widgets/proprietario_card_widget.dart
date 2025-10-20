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
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04; // 4% da largura da tela
    final avatarRadius = screenWidth * 0.08; // 8% da largura para o avatar
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            CircleAvatar(
              radius: avatarRadius,
              // TODO: Adicionar foto do proprietário ao Item/Usuario (ex: item.proprietarioFotoUrl)
              // backgroundImage: item.proprietarioFotoUrl != null && item.proprietarioFotoUrl!.isNotEmpty
              //     ? NetworkImage(item.proprietarioFotoUrl!)
              //     : null,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: /* item.proprietarioFotoUrl != null && item.proprietarioFotoUrl!.isNotEmpty
                  ? null
                  : */ Text(
                      item.proprietarioNome.isNotEmpty ? item.proprietarioNome[0].toUpperCase() : 'P',
                      style: TextStyle(fontSize: avatarRadius * 0.8, color: theme.colorScheme.onSecondaryContainer),
                    ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.proprietarioNome,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: padding * 0.25),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.proprietarioReputacao != null && item.proprietarioReputacao! > 0
                              ? item.proprietarioReputacao!.toStringAsFixed(1)
                              : 'Novo usuário',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: item.proprietarioReputacao != null && item.proprietarioReputacao! > 0
                                ? Colors.orange.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.handshake, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${item.totalAlugueis} ${item.totalAlugueis == 1 ? 'aluguel' : 'aluguéis'}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: padding * 0.5),
            Column(
              children: [
                IconButton(
                  onPressed: onChatPressed,
                  icon: const Icon(Icons.chat, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    foregroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.all(padding * 0.75),
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