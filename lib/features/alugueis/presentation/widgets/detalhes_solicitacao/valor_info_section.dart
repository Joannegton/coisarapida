import 'package:flutter/material.dart';
import '../../../domain/entities/aluguel.dart';

/// Widget com informações de valores
class ValorInfoSection extends StatelessWidget {
  final Aluguel aluguel;
  final bool isLocador;

  const ValorInfoSection({
    super.key,
    required this.aluguel,
    required this.isLocador,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duracao = aluguel.dataFim.difference(aluguel.dataInicio).inDays + 1;
    final valorDiario = aluguel.precoTotal / duracao;

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
                  Icons.payments,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Valores',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              label: 'Valor diário',
              value: 'R\$ ${valorDiario.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              label: 'Duração',
              value: '$duracao ${duracao == 1 ? 'dia' : 'dias'}',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              label: 'Subtotal',
              value: 'R\$ ${aluguel.precoTotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              label: 'Taxa de serviço (10%)',
              value: 'R\$ ${(aluguel.precoTotal * 0.1).toStringAsFixed(2)}',
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isLocador ? 'Total a receber' : 'Total a pagar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'R\$ ${(isLocador ? aluguel.precoTotal * 0.9 : aluguel.precoTotal).toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isLocador
                        ? 'O valor será creditado após a conclusão do aluguel'
                        : 'O valor será cobrado após a aprovação da solicitação',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (aluguel.caucao.valor > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield,
                          size: 20,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Caução',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'R\$ ${aluguel.caucao.valor.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Será retornado ao locatário após a devolução',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
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
    );
  }
}
