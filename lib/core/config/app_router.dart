import 'package:coisarapida/features/chat/presentation/pages/lista_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/autenticacao/presentation/pages/splash_page.dart';
import '../../features/autenticacao/presentation/pages/login_page.dart';
import '../../features/autenticacao/presentation/pages/cadastro_page.dart';
import '../../features/autenticacao/presentation/pages/esqueci_senha_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/itens/presentation/pages/anunciar_item_page.dart';
import '../../features/perfil/presentation/pages/perfil_page.dart';
import '../../features/perfil/presentation/pages/perfil_publico_page.dart';
import '../../features/configuracoes/presentation/pages/configuracoes_page.dart';
import '../constants/app_routes.dart';
import '../guards/auth_guard.dart';
import '../../features/buscar/presentation/pages/buscar_page.dart';
import '../../features/itens/presentation/pages/detalhes_item_page.dart';
import '../../features/favoritos/presentation/pages/favoritos_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';

import '../../features/seguranca/presentation/pages/aceite_contrato_page.dart';
import '../../features/seguranca/presentation/pages/status_aluguel_page.dart';
import '../../features/seguranca/presentation/pages/caucao_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authGuard = AuthGuard(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: authGuard.redirect,
    refreshListenable: authGuard,
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Autenticação
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.cadastro,
        name: 'cadastro',
        builder: (context, state) => const CadastroPage(),
      ),
      GoRoute(
        path: AppRoutes.esqueciSenha,
        name: 'esqueci-senha',
        builder: (context, state) => const EsqueciSenhaPage(),
      ),

      // Área autenticada com bottom navigation
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.buscar,
            name: 'buscar',
            builder: (context, state) => const BuscarPage(),
          ),
          GoRoute(
            path: AppRoutes.favoritos,
            name: 'favoritos',
            builder: (context, state) => const FavoritosPage(),
          ),
          GoRoute(
            path: AppRoutes.perfil,
            name: 'perfil',
            builder: (context, state) => const PerfilPage(),
          ),
        ],
      ),

      // Itens
      GoRoute(
        path: AppRoutes.anunciarItem,
        name: 'anunciar-item',
        builder: (context, state) => const AnunciarItemPage(),
      ),
      GoRoute(
        path: '${AppRoutes.detalhesItem}/:id',
        name: 'detalhes-item',
        builder: (context, state) => DetalhesItemPage(
          itemId: state.pathParameters['id']!,
        ),
      ),

      // Perfil público
      GoRoute(
        path: '/perfil-publico/:id',
        name: 'perfil-publico',
        builder: (context, state) => PerfilPublicoPage(
          usuarioId: state.pathParameters['id']!,
        ),
      ),

      // Chat
      GoRoute(
        path: AppRoutes.listaChats,
        name: 'lista-chats',
        builder: (context, state) => const ListaChatsPage(),
      ),
      GoRoute(
        path: '${AppRoutes.chat}/:id',
        name: 'chat',
        builder: (context, state) => ChatPage(
          chatId: state.pathParameters['id']!,
        ),
      ),

      // Configurações
      GoRoute(
        path: AppRoutes.configuracoes,
        name: 'configuracoes',
        builder: (context, state) => const ConfiguracoesPage(),
      ),

      // Rotas de segurança
      GoRoute(
        path: '${AppRoutes.aceiteContrato}/:aluguelId',
        name: 'aceite-contrato',
        builder: (context, state) {
          final aluguelId = state.pathParameters['aluguelId']!;
          final dadosAluguel = state.extra as Map<String, dynamic>;
          return AceiteContratoPage(
            aluguelId: aluguelId,
            dadosAluguel: dadosAluguel,
          );
        },
      ),

      GoRoute(
        path: '${AppRoutes.statusAluguel}/:aluguelId',
        name: 'status-aluguel',
        builder: (context, state) {
          final aluguelId = state.pathParameters['aluguelId']!;
          final dadosAluguel = state.extra as Map<String, dynamic>;
          return StatusAluguelPage(
            aluguelId: aluguelId,
            dadosAluguel: dadosAluguel,
          );
        },
      ),

      GoRoute(
        path: '${AppRoutes.caucao}/:aluguelId',
        name: 'caucao',
        builder: (context, state) {
          final aluguelId = state.pathParameters['aluguelId']!;
          return CaucaoPage(aluguelId: aluguelId);
        },
      ),
    ],
  );
});

// Widget para navegação inferior focada em aluguel de objetos
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.buscar)) return 1;
    if (location.startsWith(AppRoutes.favoritos)) return 2;
    if (location.startsWith(AppRoutes.perfil)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go(AppRoutes.home);
        break;
      case 1:
        GoRouter.of(context).go(AppRoutes.buscar);
        break;
      case 2:
        GoRouter.of(context).go(AppRoutes.favoritos);
        break;
      case 3:
        GoRouter.of(context).go(AppRoutes.perfil);
        break;
    }
  }
}
