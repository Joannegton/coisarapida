import 'package:flutter/foundation.dart';

class Config {
  static String get apiBaseUrl {
    // Sempre usar --dart-define para controle preciso
    final customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }

    // Para desenvolvimento, usar IP do computador na rede local
    if (kDebugMode) {
      return 'http://10.0.2.2:3000';
    }

    // Para produção, mudar para a URL real da API depois do deploy, por enquanto é teste em dispositivo fisico
    return 'http://192.168.1.5:3000';
  }

  // Método helper para desenvolvimento
  static String getDevUrl(String ip) => 'http://$ip:3000';

  // Outras configurações
  static const bool enableLogging = kDebugMode;
  static const String environment = kDebugMode ? 'debug' : 'production';
}