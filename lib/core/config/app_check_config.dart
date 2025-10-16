// Configuração do Firebase App Check
// Este arquivo contém configurações para desenvolvimento e produção

import 'package:firebase_app_check/firebase_app_check.dart';

/// Configura o Firebase App Check para desenvolvimento
/// Use esta função quando precisar testar com App Check ativado
Future<void> configurarAppCheckDesenvolvimento() async {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
}

/// Configura o Firebase App Check para produção
/// Use esta função quando for fazer deploy
Future<void> configurarAppCheckProducao() async {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );
}

/// Desabilita o App Check completamente
/// Use apenas para desenvolvimento quando o App Check estiver causando problemas
Future<void> desabilitarAppCheck() async {
  // App Check desabilitado - não fazer nada
}
