import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/autenticacao/presentation/pages/splash_page.dart';
import '../../features/autenticacao/presentation/pages/login_page.dart';
import '../../features/autenticacao/presentation/pages/cadastro_page.dart';
import '../../features/autenticacao/presentation/pages/esqueci_senha_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/entregas/presentation/pages/nova_entrega_page.dart';
import '../../features/entregas/presentation/pages/acompanhar_entrega_page.dart';
import '../../features/perfil/presentation/pages/perfil_page.dart';
import '../../features/configuracoes/presentation/pages/configuracoes_page.dart';
import '../constants/app_routes.dart';
import '../guards/auth_guard.dart';

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

      // Área autenticada
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.perfil,
            name: 'perfil',
            builder: (context, state) => const PerfilPage(),
          ),
          GoRoute(
            path: AppRoutes.configuracoes,
            name: 'configuracoes',
            builder: (context, state) => const ConfiguracoesPage(),
          ),
        ],
      ),

      // Entregas
      GoRoute(
        path: AppRoutes.novaEntrega,
        name: 'nova-entrega',
        builder: (context, state) => const NovaEntregaPage(),
      ),
      GoRoute(
        path: '${AppRoutes.acompanharEntrega}/:id',
        name: 'acompanhar-entrega',
        builder: (context, state) => AcompanharEntregaPage(
          entregaId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});

// Widget para navegação inferior
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.perfil)) return 1;
    if (location.startsWith(AppRoutes.configuracoes)) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go(AppRoutes.home);
        break;
      case 1:
        GoRouter.of(context).go(AppRoutes.perfil);
        break;
      case 2:
        GoRouter.of(context).go(AppRoutes.configuracoes);
        break;
    }
  }
}
