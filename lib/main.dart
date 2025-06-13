import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/firebase_options.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/configuracoes/presentation/providers/tema_provider.dart';
import 'features/configuracoes/presentation/providers/idioma_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Configurar orientação da tela
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar barra de status
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

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
      
      // Configuração de tema
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: temaAtual,
      
      // Configuração de idioma
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
