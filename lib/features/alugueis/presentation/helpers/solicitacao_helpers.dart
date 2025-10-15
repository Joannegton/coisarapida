import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/notification_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/verificacao_helper.dart';
import '../../domain/entities/aluguel.dart';
import '../controllers/aluguel_controller.dart';

/// Helper class com métodos reutilizáveis para gerenciar solicitações de aluguel
class SolicitacaoHelpers {
  /// Mostra diálogo de confirmação de recusa e processa a recusa
  static Future<void> recusarSolicitacao(
    BuildContext context,
    WidgetRef ref,
    Aluguel aluguel, {
    bool fecharPaginaAposRecusar = false,
  }) async {
    // Verificar se o usuário está totalmente verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(context, ref);
      return;
    }

    String? motivoRecusa;
    final motivoController = TextEditingController();

    final bool? confirmarRecusa = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(dialogContext).colorScheme.error,
              ),
              const SizedBox(width: 8),
              const Text('Recusar Solicitação'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tem certeza que deseja recusar a solicitação de ${aluguel.locatarioNome}?',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo da recusa (opcional)',
                  hintText: 'Ex: Item não disponível nas datas solicitadas',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.message_outlined),
                  helperText: 'Este motivo será enviado ao solicitante',
                  helperMaxLines: 2,
                ),
                maxLines: 3,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                motivoRecusa = motivoController.text.trim();
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.close),
              label: const Text('Recusar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
            ),
          ],
        );
      },
    );

    motivoController.dispose();

    if (confirmarRecusa == true) {
      final controller = ref.read(aluguelControllerProvider.notifier);
      final notificationManager = ref.read(notificationManagerProvider);
      
      try {
        await controller.atualizarStatusAluguel(
          aluguel.id,
          StatusAluguel.recusado,
          motivo: motivoRecusa,
        );

        // Enviar notificação ao locatário
        await notificationManager.notificarSolicitacaoRecusada(
          locatarioId: aluguel.locatarioId,
          locadorNome: aluguel.locadorNome,
          itemNome: aluguel.itemNome,
          aluguelId: aluguel.id,
          motivo: motivoRecusa,
        );

        if (context.mounted) {
          SnackBarUtils.mostrarInfo(
            context,
            'Solicitação recusada e notificação enviada ao locatário.',
          );

          // Fechar página de detalhes se solicitado
          if (fecharPaginaAposRecusar) {
            context.pop();
          }
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.mostrarErro(
            context,
            'Erro ao recusar solicitação: ${e.toString()}',
          );
        }
      }
    }
  }

  /// Mostra diálogo de confirmação de aprovação e processa a aprovação
  static Future<void> aprovarSolicitacao(
    BuildContext context,
    WidgetRef ref,
    Aluguel aluguel, {
    bool fecharPaginaAposAprovar = false,
  }) async {
    // Verificar se o usuário está totalmente verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(context, ref);
      return;
    }

    final bool? confirmarAprovacao = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Aprovar Solicitação'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deseja aprovar a solicitação de ${aluguel.locatarioNome}?',
                style: Theme.of(dialogContext).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(dialogContext).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Próximos passos:',
                          style: Theme.of(dialogContext)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• O locatário será notificado\n'
                      '• Ele terá 24h para efetuar o pagamento\n'
                      '• Após o pagamento, você será notificado',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.check),
              label: const Text('Aprovar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary,
              ),
            ),
          ],
        );
      },
    );

    if (confirmarAprovacao == true) {
      final controller = ref.read(aluguelControllerProvider.notifier);
      final notificationManager = ref.read(notificationManagerProvider);
      
      try {
        await controller.atualizarStatusAluguel(
          aluguel.id,
          StatusAluguel.aprovado,
        );

        // Enviar notificação ao locatário
        await notificationManager.notificarSolicitacaoAprovada(
          locatarioId: aluguel.locatarioId,
          locadorNome: aluguel.locadorNome,
          itemNome: aluguel.itemNome,
          aluguelId: aluguel.id,
        );

        if (context.mounted) {
          SnackBarUtils.mostrarSucesso(
            context,
            'Solicitação aprovada! O locatário foi notificado.',
          );

          // Fechar página de detalhes se solicitado
          if (fecharPaginaAposAprovar) {
            context.pop();
          }
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.mostrarErro(
            context,
            'Erro ao aprovar solicitação: ${e.toString()}',
          );
        }
      }
    }
  }
}
