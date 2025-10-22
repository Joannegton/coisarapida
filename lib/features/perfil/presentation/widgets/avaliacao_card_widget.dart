import 'package:coisarapida/features/avaliacoes/domain/entities/avaliacao.dart';
import 'package:flutter/material.dart';

class AvaliacaoCardWidget extends StatelessWidget {
  final Avaliacao avaliacao;
  final ThemeData theme;

  const AvaliacaoCardWidget({
    super.key,
    required this.avaliacao,
    required this.theme,
  });

  String _formatarData(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day} ${meses[data.month - 1]}';
  }

  Color _getStarColor(int nota) {
    if (nota >= 4) return Colors.amber.shade500;
    if (nota >= 3) return Colors.orange.shade400;
    return Colors.orange.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Stack(
        children: [
          // Background decorativo (canto superior direito)
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStarColor(avaliacao.nota).withOpacity(0.08),
              ),
            ),
          ),
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating em stars com badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Stars
                    Row(
                      children: List.generate(5, (index) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          index < avaliacao.nota ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 18,
                          color: index < avaliacao.nota
                              ? _getStarColor(avaliacao.nota)
                              : Colors.grey.shade300,
                        ),
                      )),
                    ),
                    // Badge com nota
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStarColor(avaliacao.nota).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${avaliacao.nota}.0',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getStarColor(avaliacao.nota),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Comentário (se houver)
                if (avaliacao.comentario != null && avaliacao.comentario!.isNotEmpty) ...[
                  Expanded(
                    child: Text(
                      avaliacao.comentario!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.85),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else
                  const Spacer(),
                // Footer com foto, nome e data
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: avaliacao.avaliadorFotoUrl != null && 
                          avaliacao.avaliadorFotoUrl!.isNotEmpty
                          ? NetworkImage(avaliacao.avaliadorFotoUrl!)
                          : null,
                      child: (avaliacao.avaliadorFotoUrl == null || 
                          avaliacao.avaliadorFotoUrl!.isEmpty)
                          ? Icon(
                              Icons.person,
                              size: 14,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            avaliacao.avaliadorNome,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatarData(avaliacao.data),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
