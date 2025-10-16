import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/config/firebase_options.dart';
import 'core/config/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/configuracoes/presentation/providers/tema_provider.dart';
import 'features/configuracoes/presentation/providers/idioma_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Habilitar modo Edge-to-Edge para a UI do sistema (barra de status/navegação)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Configurar orientação da tela
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar estilo inicial da barra de status para edge-to-edge.
  // O AnnotatedRegion no CoisaRapidaApp cuidará do estilo dinâmico dos ícones e cor de fundo.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Desabilitar App Check temporariamente para desenvolvimento
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.debug, // Use debug para desenvolvimento/emulador
  //   appleProvider: AppleProvider.debug,
  // );

  // Configurar handler para mensagens em background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(
    const ProviderScope(
      child: CoisaRapidaApp(),
    ),
  );
}

class CoisaRapidaApp extends ConsumerWidget {
  const CoisaRapidaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final temaAtual = ref.watch(temaProvider);
    final idiomaAtual = ref.watch(idiomaProvider);

    return MaterialApp.router(
      title: 'Coisa Rápida',
      debugShowCheckedModeBanner: false,
      
      // tema
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: temaAtual,
      
      // idioma
      locale: idiomaAtual,
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Roteamento
      routerConfig: router,
    );
  }
}
