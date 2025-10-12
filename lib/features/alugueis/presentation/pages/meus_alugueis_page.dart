import 'package:cached_network_image/cached_network_image.dart';
import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/features/alugueis/presentation/providers/aluguel_providers.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/shared/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/aluguel.dart';

class MeusAlugueisPage extends ConsumerWidget {
  const MeusAlugueisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meusAlugueisAsync = ref.watch(meusAlugueisProvider);
    final usuarioAsync = ref.watch(usuarioAtualStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text(
          'Meus Aluguéis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: meusAlugueisAsync.when(
        data: (alugueis) {
          if (alugueis.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Você ainda não possui aluguéis',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quando você alugar ou locar itens,\nos aluguéis aparecerão aqui',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          final usuario = usuarioAsync.value;
          if (usuario == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: alugueis.length,
            itemBuilder: (context, index) {
              final aluguel = alugueis[index];
              final isLocador = usuario.id == aluguel.locadorId;
              final isLocatario = usuario.id == aluguel.locatarioId;

              return _buildAluguelCard(context, theme, aluguel, isLocador, isLocatario);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar seus aluguéis',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(meusAlugueisProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildAluguelCard(BuildContext context, ThemeData theme, Aluguel aluguel, bool isLocador, bool isLocatario) {
    final duracao = aluguel.dataFim.difference(aluguel.dataInicio).inDays + 1;
    final papelUsuario = isLocador ? 'Locador' : 'Locatário';
    final corPapel = isLocador ? theme.colorScheme.primary : theme.colorScheme.secondary;
    final iconePapel = isLocador ? Icons.store : Icons.person;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.detalhesSolicitacao, extra: aluguel);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com papel do usuário
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: corPapel.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: corPapel.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconePapel,
                          size: 16,
                          color: corPapel,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          papelUsuario,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: corPapel,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(theme, aluguel.status),
                ],
              ),

              const SizedBox(height: 12),

              // Imagem e informações principais
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: aluguel.itemFotoUrl,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aluguel.itemNome,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'R ${aluguel.precoTotal.toStringAsFixed(2)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Informações adicionais
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
                      icon: isLocador ? Icons.person_outline : Icons.store,
                      label: isLocador ? 'Locatário' : 'Locador',
                      value: isLocador ? aluguel.locatarioNome : aluguel.locadorNome,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      theme,
                      icon: Icons.calendar_today,
                      label: 'Período',
                      value: '${Utils.formatarData(aluguel.dataInicio)} - ${Utils.formatarData(aluguel.dataFim)}',
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
            ],
          ),
        ),
      ),
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

  Widget _buildStatusBadge(ThemeData theme, StatusAluguel status) {
    Color badgeColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case StatusAluguel.solicitado:
        badgeColor = theme.colorScheme.error;
        textColor = theme.colorScheme.onError;
        label = 'PENDENTE';
        icon = Icons.pending;
        break;
      case StatusAluguel.aprovado:
        badgeColor = Colors.green;
        textColor = Colors.white;
        label = 'ATIVO';
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
        label = status.name.toUpperCase();
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}