import 'package:coisarapida/features/avaliacoes/domain/entities/avaliacao.dart';
import 'package:flutter/material.dart';

class AvaliacaoItemWidget extends StatelessWidget {
  final Avaliacao avaliacao;
  final ThemeData theme;

  const AvaliacaoItemWidget({
    super.key,
    required this.avaliacao,
    required this.theme,
  });

  String _formatarData(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: avaliacao.avaliadorFotoUrl != null && avaliacao.avaliadorFotoUrl!.isNotEmpty
                ? NetworkImage(avaliacao.avaliadorFotoUrl!)
                : null,
            child: (avaliacao.avaliadorFotoUrl == null || avaliacao.avaliadorFotoUrl!.isEmpty)
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      avaliacao.avaliadorNome,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        Icons.star,
                        size: 14,
                        color: index < avaliacao.nota
                            ? Colors.orange
                            : Colors.grey.shade300,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (avaliacao.comentario != null && avaliacao.comentario!.isNotEmpty)
                  Text(
                    avaliacao.comentario!,
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatarData(avaliacao.data),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}