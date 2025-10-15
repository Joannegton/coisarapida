import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handler para mensagens em background (deve estar no nível top)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Background message: ${message.messageId}');
  debugPrint('📨 Title: ${message.notification?.title}');
  debugPrint('📨 Body: ${message.notification?.body}');
  debugPrint('📨 Data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Solicitar permissões
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('⚠️ Permissão de notificação negada');
        return;
      }

      // 2. Configurar notificações locais (para Android)
      await _setupLocalNotifications();

      // 3. Obter e salvar o FCM token
      await _setupFCMToken();

      // 4. Configurar handlers de mensagens
      _setupMessageHandlers();

      _initialized = true;
      debugPrint('✅ NotificationService inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar NotificationService: $e');
    }
  }

  /// Solicita permissões de notificação
  Future<NotificationSettings> _requestPermission() async {
    return await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
      announcement: false,
      carPlay: false,
    );
  }

  /// Configura notificações locais para Android
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Criar canal de notificação para Android
    const androidChannel = AndroidNotificationChannel(
      'aluguel_notifications',
      'Notificações de Aluguel',
      description: 'Notificações sobre solicitações e atualizações de aluguéis',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Configura e salva o FCM token
  Future<void> _setupFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      // Listener para quando o token é atualizado
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token atualizado: $newToken');
        // TODO: Atualizar no Firestore se o usuário estiver logado
      });
    } catch (e) {
      debugPrint('❌ Erro ao obter FCM token: $e');
    }
  }

  /// Salva o FCM token do usuário no Firestore
  Future<void> saveFCMTokenForUser(String userId) async {
    if (_fcmToken == null) {
      debugPrint('⚠️ FCM Token não disponível');
      return;
    }

    try {
      await _firestore.collection('usuarios').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ FCM Token salvo para usuário $userId');
    } catch (e) {
      debugPrint('❌ Erro ao salvar FCM token: $e');
    }
  }

  /// Remove o FCM token do usuário (logout)
  Future<void> removeFCMTokenForUser(String userId) async {
    try {
      await _firestore.collection('usuarios').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      debugPrint('✅ FCM Token removido para usuário $userId');
    } catch (e) {
      debugPrint('❌ Erro ao remover FCM token: $e');
    }
  }

  /// Configura os handlers de mensagens
  void _setupMessageHandlers() {
    // Mensagem recebida quando app está em foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Mensagem que abriu o app (de background ou terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Verificar se o app foi aberto por uma notificação (quando estava terminated)
    _checkInitialMessage();
  }

  /// Handler para mensagens quando app está em foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message: ${message.messageId}');
    
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      // Mostrar notificação local
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'aluguel_notifications',
            'Notificações de Aluguel',
            channelDescription: 'Notificações sobre solicitações e atualizações de aluguéis',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['aluguelId'],
      );
    }
  }

  /// Handler para quando usuário toca na notificação
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 Notificação clicada: ${message.messageId}');
    debugPrint('🔔 Data: ${message.data}');
    
    // TODO: Navegar para a tela apropriada baseado no tipo de notificação
    final aluguelId = message.data['aluguelId'];
    if (aluguelId != null) {
      // Implementar navegação para detalhes do aluguel
      debugPrint('🔔 Navegando para aluguel: $aluguelId');
    }
  }

  /// Callback quando usuário toca na notificação local
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notificação local clicada');
    final aluguelId = response.payload;
    if (aluguelId != null) {
      debugPrint('🔔 Navegando para aluguel: $aluguelId');
      // TODO: Implementar navegação
    }
  }

  /// Verifica se o app foi aberto por uma notificação
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Verifica se as permissões de notificação estão concedidas
  Future<bool> hasPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Solicita permissão de notificação manualmente
  Future<bool> requestPermission() async {
    try {
      final settings = await _requestPermission();
      final authorized = settings.authorizationStatus == AuthorizationStatus.authorized;
      
      if (authorized) {
        debugPrint('✅ Permissão de notificação concedida');
        // Se a permissão foi concedida agora, inicializar o serviço
        if (!_initialized) {
          await initialize();
        }
      } else {
        debugPrint('❌ Permissão de notificação negada');
      }
      
      return authorized;
    } catch (e) {
      debugPrint('❌ Erro ao solicitar permissão: $e');
      return false;
    }
  }

  /// Retorna o FCM token atual
  String? get fcmToken => _fcmToken;

  /// Verifica se o serviço está inicializado
  bool get isInitialized => _initialized;
}
