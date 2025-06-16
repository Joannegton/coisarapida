import 'package:coisarapida/features/avaliacoes/domain/entities/avaliacao.dart';
import 'package:flutter/material.dart';
import 'avaliacao_item_widget.dart'; // Importe o widget de item de avaliação

class PerfilAvaliacoesWidget extends StatelessWidget {
  final List<Avaliacao> avaliacoes;
  final ThemeData theme;
  final Function(BuildContext, List<Avaliacao>) onVerTodasPressed;

  const PerfilAvaliacoesWidget({
    super.key,
    required this.avaliacoes,
    required this.theme,
    required this.onVerTodasPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_border, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Avaliações Recebidas (${avaliacoes.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (avaliacoes.isEmpty)
              const Text('Nenhuma avaliação recebida ainda.'),
            ...avaliacoes.take(3).map((av) => AvaliacaoItemWidget(avaliacao: av, theme: theme)),
            if (avaliacoes.length > 3) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => onVerTodasPressed(context, avaliacoes),
                  child: const Text('Ver todas'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}