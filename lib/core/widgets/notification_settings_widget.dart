import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import 'notification_permission_dialog.dart';

/// Widget para configurações de notificações
class NotificationSettingsWidget extends ConsumerStatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  ConsumerState<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends ConsumerState<NotificationSettingsWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationService = ref.watch(notificationServiceProvider);

    return FutureBuilder<bool>(
      future: notificationService.hasPermission(),
      builder: (context, snapshot) {
        final hasPermission = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Notificações Push',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Receba atualizações em tempo real sobre suas solicitações de aluguel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  _buildPermissionStatus(hasPermission, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionStatus(bool hasPermission, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasPermission
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasPermission
              ? theme.colorScheme.primary.withOpacity(0.2)
              : theme.colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.notifications_active : Icons.notifications_off,
            color: hasPermission ? theme.colorScheme.primary : theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPermission ? 'Notificações Ativadas' : 'Notificações Desativadas',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasPermission ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                ),
                Text(
                  hasPermission
                      ? 'Você receberá notificações sobre suas solicitações'
                      : 'Permita notificações para receber atualizações',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!hasPermission)
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.notifications_active, size: 16),
              label: const Text('Habilitar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: theme.textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _requestPermission() async {
    final granted = await showNotificationPermissionDialog(context);
    if (granted == true && mounted) {
      setState(() {}); // Recarregar o status
    }
  }
}
