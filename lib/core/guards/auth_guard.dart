import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/autenticacao/domain/entities/status_endereco.dart';
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
    final usuario = authState.value;

    final isOnSplash = state.uri.toString() == AppRoutes.splash;
    final isOnAuthPages = [
      AppRoutes.login,
      AppRoutes.cadastro,
      AppRoutes.esqueciSenha,
    ].contains(state.uri.toString());

    final isOnVerificacaoPages = [
      AppRoutes.verificacaoTelefone,
      AppRoutes.verificacaoResidencia,
    ].contains(state.uri.toString());

    final isOnAvaliacaoPage = state.uri.toString().startsWith(AppRoutes.avaliacao);
    
    // Rotas que não devem ser redirecionadas (ex: deep links de pagamento)
    final isOnProtectedPages = state.uri.toString().startsWith(AppRoutes.statusAluguel);

    // Se está na splash, deixa continuar
    if (isOnSplash) return null;

    // Se não está logado e não está em páginas de auth, redireciona para login
    if (!isLoggedIn && !isOnAuthPages) {
      return AppRoutes.login;
    }

    // Se está logado, verificar fluxo de verificações
    if (isLoggedIn && usuario != null) {
      final statusEndereco = usuario.statusEndereco;
      
      // Se está em páginas de auth e já está logado, verificar verificações
      if (isOnAuthPages) {
        // Se telefone não verificado, vai para verificação de telefone
        if (usuario.telefone == null || usuario.telefone!.isEmpty) {
          return AppRoutes.verificacaoTelefone;
        }
        // Se telefone verificado mas endereço não está aprovado ou em análise, vai para verificação
        if (statusEndereco == null || statusEndereco == StatusEndereco.rejeitado) {
          return AppRoutes.verificacaoResidencia;
        }
        // Tudo verificado ou em análise, vai para home
        return AppRoutes.home;
      }

      // Se não está em páginas de verificação, verificar se precisa ir para elas
      if (!isOnVerificacaoPages && !isOnAvaliacaoPage && !isOnProtectedPages) {
        // Se telefone não verificado, redireciona para verificação de telefone
        if (usuario.telefone == null || usuario.telefone!.isEmpty) {
          return AppRoutes.verificacaoTelefone;
        }
        // Se endereço não está aprovado ou em análise, redireciona para verificação
        if (statusEndereco == null || statusEndereco == StatusEndereco.rejeitado) {
          return AppRoutes.verificacaoResidencia;
        }
      }

      
      // Se está em página de verificação de telefone mas já verificou, vai para próximo passo
      if (state.uri.toString() == AppRoutes.verificacaoTelefone && usuario.telefone != null) {
        if (statusEndereco == null || statusEndereco == StatusEndereco.rejeitado) {
          return AppRoutes.verificacaoResidencia;
        }
        return AppRoutes.home;
      }

      // Se está em página de verificação de endereço mas já está aprovado ou em análise, vai para home
      if (
        state.uri.toString() == AppRoutes.verificacaoResidencia && 
        statusEndereco != null && 
        (statusEndereco == StatusEndereco.aprovado || statusEndereco == StatusEndereco.emAnalise)
      ) {
        return AppRoutes.home;
      }

      // Se está logado e verificado (aprovado), verificar se há avaliações pendentes
      if (!isOnAvaliacaoPage && usuario.telefone != null && statusEndereco == StatusEndereco.aprovado) {
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
    }

    return null;
  }
}
