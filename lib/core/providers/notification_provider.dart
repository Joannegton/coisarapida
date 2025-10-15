import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/notification_manager.dart';

/// Provider do serviço de notificações
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider do gerenciador de notificações
final notificationManagerProvider = Provider<NotificationManager>((ref) {
  return NotificationManager();
});

/// Provider para inicialização do serviço de notificações
final notificationInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  await service.initialize();
  return service.isInitialized;
});
