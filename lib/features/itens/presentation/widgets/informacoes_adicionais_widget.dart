import 'package:flutter/material.dart';
import '../../domain/entities/item.dart';

class InformacoesAdicionaisWidget extends StatelessWidget {
  final Item item;
  final String Function(DateTime) formatarData;

  const InformacoesAdicionaisWidget({
    super.key,
    required this.item,
    required this.formatarData,
  });

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Adicionais',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Caução',
              item.caucao != null ? 'R\$ ${item.caucao!.toStringAsFixed(2)}' : 'Não exigido',
            ),
            _buildInfoRow('Aprovação', item.aprovacaoAutomatica ? 'Automática' : 'Manual'),
            _buildInfoRow('Total de aluguéis do item', '${item.totalAlugueis}'),
            _buildInfoRow('Avaliação do item', '${item.avaliacao.toStringAsFixed(1)} ⭐'),
            _buildInfoRow('Anunciado em', formatarData(item.criadoEm)),
          ],
        ),
      ),
    );
  }
}