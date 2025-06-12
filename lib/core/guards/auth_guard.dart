import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/autenticacao/presentation/providers/auth_provider.dart';
import '../constants/app_routes.dart';

/// Guard para controlar acesso às rotas baseado na autenticação
class AuthGuard extends ChangeNotifier {
  final Ref _ref;

  AuthGuard(this._ref) {
    // Escutar mudanças no estado de autenticação
    _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final isLoggedIn = authState.hasValue && authState.value != null;
    
    final isOnSplash = state.uri.toString() == AppRoutes.splash;
    final isOnAuthPages = [
      AppRoutes.login,
      AppRoutes.cadastro,
      AppRoutes.esqueciSenha,
    ].contains(state.uri.toString());

    // Se está na splash, deixa continuar
    if (isOnSplash) return null;

    // Se não está logado e não está em páginas de auth, redireciona para login
    if (!isLoggedIn && !isOnAuthPages) {
      return AppRoutes.login;
    }

    // Se está logado e está em páginas de auth, redireciona para home
    if (isLoggedIn && isOnAuthPages) {
      return AppRoutes.home;
    }

    return null;
  }
}
