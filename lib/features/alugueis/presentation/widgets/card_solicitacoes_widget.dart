import 'package:cached_network_image/cached_network_image.dart';
import 'package:coisarapida/features/alugueis/domain/entities/aluguel.dart';
import 'package:coisarapida/shared/utils.dart';
import 'package:flutter/material.dart';

class CardSolicitacoesWidget extends StatelessWidget {
  final Aluguel aluguel;
  final VoidCallback onRecusarSolicitacao;
  final VoidCallback onAprovarSolicitacao;
  final VoidCallback onChatPressed;

  const CardSolicitacoesWidget({
    super.key,
    required this.aluguel,
    required this.onRecusarSolicitacao, 
    required this.onAprovarSolicitacao,
    required this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.surface,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: aluguel.itemFotoUrl,
                    height: 56,
                    width: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                    errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_rounded, size: 30),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  aluguel.itemNome,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            theme, 
            icon: Icons.person_outline_rounded,
            label: 'Solicitante:',
            value: aluguel.locatarioNome,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            theme,
            icon: Icons.calendar_today_rounded,
            label: 'Período:',
            value: '${Utils.formatarData(aluguel.dataInicio)} a ${Utils.formatarData(aluguel.dataFim)}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            theme,
            icon: Icons.monetization_on_outlined,
            label: 'Valor Total:',
            value: 'R\$ ${aluguel.precoTotal.toStringAsFixed(2)}',
          ),
          if (aluguel.observacoesLocatario != null && aluguel.observacoesLocatario!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildObservationsSection(theme),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: onRecusarSolicitacao,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Recusar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text('Aprovar'),
                onPressed: onAprovarSolicitacao, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(88, 36),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.chat_sharp, 
                  size: 30, 
                  color: theme.colorScheme.primary
                ),
                onPressed: onChatPressed,
                tooltip: 'Conversar com ${aluguel.locatarioNome}',
              ),  
            ],
          ),
           
        ]
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant), // const
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildObservationsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(102),
        borderRadius: BorderRadius.circular(8),
      ),
      child:  Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              aluguel.observacoesLocatario!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}