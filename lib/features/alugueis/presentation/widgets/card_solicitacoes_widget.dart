import 'package:cached_network_image/cached_network_image.dart';
import 'package:coisarapida/features/alugueis/domain/entities/aluguel.dart';
import 'package:coisarapida/shared/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';

class CardSolicitacoesWidget extends StatefulWidget {
  final Aluguel aluguel;
  final VoidCallback onRecusarSolicitacao;

  const CardSolicitacoesWidget({
    super.key,
    required this.aluguel,
    required this.onRecusarSolicitacao, 
  });

  @override
  State<CardSolicitacoesWidget> createState() => _CardSolicitacoesWidgetState();
}

class _CardSolicitacoesWidgetState extends State<CardSolicitacoesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duracao = widget.aluguel.dataFim.difference(widget.aluguel.dataInicio).inDays + 1;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            context.push(AppRoutes.detalhesSolicitacao, extra: widget.aluguel);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com imagem e título
                Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: widget.aluguel.itemFotoUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 70,
                            height: 70,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 70,
                            height: 70,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.image_not_supported, size: 30),
                          ),
                        ),
                      ),
                      // Badge de status
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _buildStatusBadge(theme),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Informações principais
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.aluguel.itemNome,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Valor
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.payments,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'R\$ ${widget.aluguel.precoTotal.toStringAsFixed(2)}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Informações do solicitante e período
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      theme,
                      icon: Icons.person_outline,
                      label: 'Solicitante',
                      value: widget.aluguel.locatarioNome,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      theme,
                      icon: Icons.calendar_today,
                      label: 'Período',
                      value: '${Utils.formatarData(widget.aluguel.dataInicio)} - ${Utils.formatarData(widget.aluguel.dataFim)}',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      theme,
                      icon: Icons.schedule,
                      label: 'Duração',
                      value: '$duracao ${duracao == 1 ? 'dia' : 'dias'}',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botões de ação
              Row(
                children: [
                  // Botão recusar só aparece para solicitações pendentes
                  if (widget.aluguel.status == StatusAluguel.solicitado) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onRecusarSolicitacao,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Recusar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: widget.aluguel.status == StatusAluguel.solicitado ? 2 : 1,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push(AppRoutes.detalhesSolicitacao, extra: widget.aluguel);
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Ver detalhes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      )
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color badgeColor;
    Color textColor;
    String label;
    IconData icon;

    switch (widget.aluguel.status) {
      case StatusAluguel.solicitado:
        badgeColor = theme.colorScheme.error;
        textColor = theme.colorScheme.onError;
        label = 'NOVO';
        icon = Icons.new_releases;
        break;
      case StatusAluguel.aprovado:
        badgeColor = Colors.green;
        textColor = Colors.white;
        label = 'APROVADO';
        icon = Icons.check_circle;
        break;
      case StatusAluguel.recusado:
        badgeColor = Colors.grey;
        textColor = Colors.white;
        label = 'RECUSADO';
        icon = Icons.cancel;
        break;
      default:
        badgeColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        label = widget.aluguel.status.name.toUpperCase();
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: textColor,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}