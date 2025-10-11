import 'package:flutter/material.dart';
import '../../../domain/entities/aluguel.dart';
import '../../../../../shared/utils.dart';

/// Widget com informações do período de aluguel
class PeriodoInfoSection extends StatelessWidget {
  final Aluguel aluguel;

  const PeriodoInfoSection({
    super.key,
    required this.aluguel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duracao = aluguel.dataFim.difference(aluguel.dataInicio).inDays + 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Período do Aluguel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              icon: Icons.event_available,
              label: 'Início',
              value: Utils.formatarData(aluguel.dataInicio),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.event_busy,
              label: 'Devolução',
              value: Utils.formatarData(aluguel.dataFim),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.timelapse,
              label: 'Duração',
              value: '$duracao ${duracao == 1 ? 'dia' : 'dias'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
