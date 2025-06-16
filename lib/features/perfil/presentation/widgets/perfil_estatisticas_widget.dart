import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:flutter/material.dart';

class PerfilEstatisticasWidget extends StatelessWidget {
  final Usuario usuario;
  final ThemeData theme;

  const PerfilEstatisticasWidget({
    super.key,
    required this.usuario,
    required this.theme,
  });

  Widget _buildEstatistica(String titulo, String valor, IconData icone, Color cor) {
    return Column(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildEstatistica(
                'Itens Anunciados', // TODO: Ajustar para o campo correto em Usuario, se existir
                '${usuario.totalItensAlugados}', // Exemplo, ajuste conforme seus campos
                Icons.inventory,
                theme.colorScheme.primary,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade300,
            ),
            Expanded(
              child: _buildEstatistica(
                'Aluguéis Realizados',
                '${usuario.totalAlugueis}',
                Icons.handshake,
                theme.colorScheme.secondary,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade300,
            ),
            Expanded(
              child: _buildEstatistica(
                'Avaliação',
                '${usuario.reputacao.toStringAsFixed(1)} ⭐',
                Icons.star,
                Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}