import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/notification_provider.dart';

/// Diálogo para solicitar permissão de notificações
class NotificationPermissionDialog extends ConsumerStatefulWidget {
  const NotificationPermissionDialog({super.key});

  @override
  ConsumerState<NotificationPermissionDialog> createState() => _NotificationPermissionDialogState();
}

class _NotificationPermissionDialogState extends ConsumerState<NotificationPermissionDialog> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Permitir Notificações'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para receber atualizações sobre suas solicitações de aluguel, precisamos da sua permissão para enviar notificações.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Você será notificado quando:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFeatureItem('Nova solicitação recebida'),
                _buildFeatureItem('Solicitação aprovada ou recusada'),
                _buildFeatureItem('Pagamento confirmado'),
                _buildFeatureItem('Lembretes de devolução'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isRequesting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Agora Não'),
        ),
        ElevatedButton.icon(
          onPressed: _isRequesting ? null : _requestPermission,
          icon: _isRequesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.notifications),
          label: Text(_isRequesting ? 'Solicitando...' : 'Permitir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);

    try {
      final notificationService = ref.read(notificationServiceProvider);
      final granted = await notificationService.requestPermission();

      if (mounted) {
        Navigator.of(context).pop(granted);

        if (granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Notificações habilitadas!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Permissão de notificações negada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao solicitar permissão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }
}

/// Função utilitária para mostrar o diálogo de permissão
Future<bool?> showNotificationPermissionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const NotificationPermissionDialog(),
  );
}
