import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:flutter/material.dart';

class MinhasEstatisticaWidget extends StatelessWidget {
  final Usuario usuario;

  const MinhasEstatisticaWidget({
    super.key,
    required this.usuario,

  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minhas Estatísticas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _cardEstatisticaWidget(
                    'Itens Anunciados',
                    usuario.totalItensAlugados.toString(),
                    Icons.inventory,
                    theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _cardEstatisticaWidget(
                    'Aluguéis Realizados',
                    usuario.totalAlugueis.toString(),
                    Icons.handshake,
                    theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _cardEstatisticaWidget(
                    'Avaliação',
                    '${usuario.reputacao.toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardEstatisticaWidget(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}