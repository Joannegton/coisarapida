import 'package:flutter/foundation.dart';

class Config {
  // === DETECÇÃO DE AMBIENTE ===
  static String get environment {
    return const String.fromEnvironment('ENVIRONMENT',
        defaultValue: String.fromEnvironment('ENVIRONMENT',
            defaultValue: kDebugMode ? 'dev' : 'prod'));
  }

  static bool get isDevelopment => environment == 'dev';
  static bool get isProduction => environment == 'prod';

  // === URL DA API ===
  static String get apiBaseUrl {
    // Primeiro tenta pegar da variável de ambiente específica
    final customUrl = const String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }

    // URLs específicas por ambiente
    if (isDevelopment) {
      return const String.fromEnvironment('API_BASE_URL_DEV',
          defaultValue: 'http://10.0.2.2:3000');
    } else {
      return const String.fromEnvironment('API_BASE_URL_PROD',
          defaultValue: 'http://192.168.1.6:3000');
    }
  }

  // === CONFIGURAÇÕES GERAIS ===
  static bool get enableDetailedLogs {
    return const bool.fromEnvironment('ENABLE_DETAILED_LOGS',
        defaultValue: kDebugMode);
  }

  static bool get enableLogging => enableDetailedLogs || kDebugMode;

  // === HELPERS ===
  static String getDevUrl(String ip) => 'http://$ip:3000';
  static String getProdUrl(String domain) => 'https://$domain';

  static String get environmentName {
    return isDevelopment ? 'Desenvolvimento' : 'Produção';
  }
}