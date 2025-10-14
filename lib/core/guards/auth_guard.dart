import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/autenticacao/presentation/providers/auth_provider.dart';
import '../../features/avaliacoes/presentation/providers/avaliacao_providers.dart';
import '../constants/app_routes.dart';

/// Guard para controlar acesso às rotas baseado na autenticação
class AuthGuard extends ChangeNotifier {
  final Ref _ref;

  AuthGuard(this._ref) {
    // Escutar mudanças no estado de autenticação
    _ref.listen(usuarioAtualStreamProvider, (previous, next) {
      notifyListeners();
    });

    // Escutar mudanças nas avaliações pendentes
    _ref.listen(avaliacoesPendentesProvider, (previous, next) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(usuarioAtualStreamProvider);
    final isLoggedIn = authState.hasValue && authState.value != null;

    final isOnSplash = state.uri.toString() == AppRoutes.splash;
    final isOnAuthPages = [
      AppRoutes.login,
      AppRoutes.cadastro,
      AppRoutes.esqueciSenha,
    ].contains(state.uri.toString());

    final isOnAvaliacaoPage = state.uri.toString().startsWith(AppRoutes.avaliacao);

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

    // Se está logado, verificar se há avaliações pendentes
    if (isLoggedIn && !isOnAvaliacaoPage) {
      final avaliacoesPendentes = _ref.read(avaliacoesPendentesProvider);
      if (avaliacoesPendentes.hasValue && avaliacoesPendentes.value!.isNotEmpty) {
        // Pegar a primeira avaliação pendente
        final primeiraAvaliacao = avaliacoesPendentes.value!.first;
        final avaliadoId = primeiraAvaliacao['avaliadoId'] as String?;
        final avaliadoNome = primeiraAvaliacao['avaliadoNome'] as String? ?? 'Usuário';
        final avaliadoFoto = primeiraAvaliacao['avaliadoFoto'] as String?;
        final aluguelId = primeiraAvaliacao['aluguelId'] as String?;
        final itemId = primeiraAvaliacao['itemId'] as String?;
        final itemNome = primeiraAvaliacao['itemNome'] as String?;
        final avaliacaoPendenteId = primeiraAvaliacao['id'] as String?;

        if (avaliadoId != null && aluguelId != null) {
          // Construir query string com todos os parâmetros
          final queryParams = <String, String>{
            'avaliadoId': avaliadoId,
            'avaliadoNome': avaliadoNome,
            if (avaliadoFoto != null) 'avaliadoFoto': avaliadoFoto,
            'aluguelId': aluguelId,
            if (itemId != null) 'itemId': itemId,
            if (itemNome != null) 'itemNome': itemNome,
            'isObrigatoria': 'true',
            if (avaliacaoPendenteId != null) 'avaliacaoPendenteId': avaliacaoPendenteId,
          };

          final queryString = queryParams.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&');

          // Redirecionar para página de avaliação obrigatória
          return '${AppRoutes.avaliacao}?$queryString';
        }
      }
    }

    return null;
  }
}
