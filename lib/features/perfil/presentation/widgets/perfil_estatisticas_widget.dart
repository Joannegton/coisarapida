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
    debugPrint('Reputação do usuário: ${usuario.reputacao.toStringAsFixed(1)}');
    return Column(
      children: [
        Icon(icone, color: cor, size: 28),
        const SizedBox(height: 8),
        Text(
          valor,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        Text(
          titulo,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _buildEstatistica(
          'Anúncios',
          '${usuario.totalItensAlugados}',
          Icons.inventory,
          theme.colorScheme.primary,
        ),
        _buildEstatistica(
          'Alugados',
          '${usuario.totalAlugueis}',
          Icons.handshake,
          theme.colorScheme.secondary,
        ),
        _buildEstatistica(
          'Avaliação',
          usuario.reputacao.toStringAsFixed(1),
          Icons.star,
          Colors.orange,
        ),
      ],
    );
  }
}