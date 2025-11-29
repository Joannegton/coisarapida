import 'package:coisarapida/features/alugueis/presentation/pages/solicitacoes_aluguel_page.dart';
import 'package:coisarapida/features/alugueis/presentation/pages/solicitar_aluguel_page.dart';
import 'package:coisarapida/features/alugueis/presentation/pages/status_aluguel_page.dart';
import 'package:coisarapida/features/alugueis/presentation/pages/detalhes_solicitacao_page.dart';
import 'package:coisarapida/features/alugueis/domain/entities/aluguel.dart';
import 'package:coisarapida/features/avaliacoes/presentation/pages/avaliacao_page.dart';
import 'package:coisarapida/features/chat/presentation/pages/lista_chat_page.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/menu/presentation/pages/menu_mais_page.dart';
import 'package:coisarapida/features/seguranca/presentation/pages/verificacao_residencia_page.dart';
import 'package:coisarapida/features/seguranca/presentation/pages/verificacao_telefone_page.dart';
import 'package:coisarapida/features/vendas/presentation/pages/acompanhamento_venda_page.dart';
import 'package:coisarapida/features/vendas/presentation/pages/comprar_item_page.dart';
import 'package:coisarapida/shared/widgets/botton_navigation_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisarapida/core/providers/payment_deep_link_provider.dart';
import 'package:coisarapida/core/utils/snackbar_utils.dart';

import '../../features/autenticacao/presentation/pages/splash_page.dart';
import '../../features/autenticacao/presentation/pages/login_page.dart';
import '../../features/autenticacao/presentation/pages/cadastro_page.dart';
import '../../features/autenticacao/presentation/pages/esqueci_senha_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/itens/presentation/pages/anunciar_item_page.dart';
import '../../features/perfil/presentation/pages/perfil_page.dart';
import '../../features/perfil/presentation/pages/perfil_publico_page.dart';
import '../../features/configuracoes/presentation/pages/configuracoes_page.dart';
import '../../features/notificacoes/presentation/pages/notificacoes_page.dart';
import '../constants/app_routes.dart';
import '../guards/auth_guard.dart';
import '../../features/buscar/presentation/pages/buscar_page.dart';
import '../../features/itens/presentation/pages/detalhes_item_page.dart';
import '../../features/favoritos/presentation/pages/favoritos_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/itens/presentation/pages/editar_item_page.dart';
import '../../features/itens/presentation/pages/meus_itens_page.dart';

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
        builder: (context, state, child) => BottonNavigation(child: child),
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
            path: AppRoutes.listaChats,
            name: 'lista-chats',
            builder: (context, state) => const ListaChatsPage(),
          ),
          GoRoute(
            path: AppRoutes.solicitacoesAluguel,
            name: 'solicitacoes-aluguel',
            builder: (context, state) => const SolicitacoesAluguelPage(),
          ),
          GoRoute(
            path: AppRoutes.menu,
            name: 'menu',
            builder: (context, state) => const MenuMaisPage(),
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
      GoRoute(
        path: '${AppRoutes.editarItem}/:id',
        name: 'editar-item',
        builder: (context, state) => EditarItemPage(
          itemId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.meusItens,
        name: 'meus-itens',
        builder: (context, state) => const MeusItensPage(),
      ),

      // Perfil
      GoRoute(
        path: '${AppRoutes.perfilPublico}/:id',
        name: 'perfil-publico',
        builder: (context, state) => PerfilPublicoPage(
          usuarioId: state.pathParameters['id']!,
        ),
      ),

      GoRoute(
        path: '${AppRoutes.editarPerfil}',
        name: 'editar-perfil',
        builder: (context, state) => const MenuPage(),
      ),

      // Chat
      // A rota principal de lista de chats agora está dentro do ShellRoute.
      // Se você precisar de uma rota de lista de chats fora do Shell, pode mantê-la aqui.
      // GoRoute(
      //   path: AppRoutes.listaChats, // Exemplo: /chats-fora-do-shell
      //   name: 'lista-chats-global',
      //   builder: (context, state) => const ListaChatsPage(),
      // ),
      GoRoute(
        path:
            '${AppRoutes.chat}/:chatId', // Ex: /chat/chat_OTHERUSERID ou /chat/CHATDOCUMENTID_OTHERUSERID
        name: 'chat',
        builder: (context, state) {
          String chatId = state.pathParameters['chatId']!;

          // Extrai o otherUserId do chatId se extra não estiver disponível
          final otherUserId = (state.extra as String?) ??
              (chatId.startsWith('chat_') ? chatId.substring(5) : chatId);

          return ChatPage(chatId: chatId, otherUserId: otherUserId);
        },
      ),

      // Configurações
      GoRoute(
        path: AppRoutes.configuracoes,
        name: 'configuracoes',
        builder: (context, state) => const ConfiguracoesPage(),
      ),

      // Notificações
      GoRoute(
        path: AppRoutes.notificacoes,
        name: 'notificacoes',
        builder: (context, state) => const NotificacoesPage(),
      ),

      // alugueis
      GoRoute(
        path: AppRoutes.solicitarAluguel,
        name: 'solicitar-aluguel',
        builder: (context, state) {
          final item = state.extra as Item?;
          if (item == null) {
            return const Scaffold(
                body: Center(
                    child: Text("Item não fornecido para solicitação.")));
          }
          return SolicitarAluguelPage(item: item);
        },
      ),

      GoRoute(
        path: '${AppRoutes.statusAluguel}/:aluguelId',
        name: 'status-aluguel',
        builder: (context, state) {
          final aluguelId = state.pathParameters['aluguelId']!;
          final dadosAluguel = (state.extra as Map<String, dynamic>?) ?? {};
          return StatusAluguelPage(
            aluguelId: aluguelId,
            dadosAluguel: dadosAluguel,
          );
        },
      ),

      GoRoute(
        path: '/acompanhamento-venda/:vendaId',
        name: 'acompanhamento-venda',
        builder: (context, state) {
          final vendaId = state.pathParameters['vendaId']!;
          final dadosVenda = (state.extra as Map<String, dynamic>?) ?? {};
          return AcompanhamentoVendaPage(
            vendaId: vendaId,
            dadosVenda: dadosVenda,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.detalhesSolicitacao,
        name: 'detalhes-solicitacao',
        builder: (context, state) {
          final aluguel = state.extra as Aluguel?;
          if (aluguel == null) {
            return const Scaffold(
                body: Center(child: Text("Solicitação não fornecida.")));
          }
          return DetalhesSolicitacaoPage(aluguel: aluguel);
        },
      ),

      GoRoute(
        path: AppRoutes.favoritos,
        name: 'favoritos',
        builder: (context, state) => const FavoritosPage(),
      ),

      // vendas
      GoRoute(
        path: AppRoutes.comprarItem,
        name: 'comprar-item',
        builder: (context, state) {
          final item = state.extra as Item?;
          if (item == null) {
            return const Scaffold(
                body: Center(child: Text("Item não fornecido para compra.")));
          }
          return ComprarItemPage(item: item);
        },
      ),
      // Verificação
      GoRoute(
        path: AppRoutes.verificacaoTelefone,
        name: 'verificacao-telefone',
        builder: (context, state) {
          return const VerificacaoTelefonePage();
        },
      ),
      GoRoute(
        path: AppRoutes.verificacaoResidencia,
        name: 'verificacao-residencia',
        builder: (context, state) {
          return const VerificacaoResidenciaPage();
        },
      ),

      // Avaliação
      GoRoute(
        path: AppRoutes.avaliacao,
        name: 'avaliacao',
        builder: (context, state) {
          final avaliadoId = state.uri.queryParameters['avaliadoId'];
          final avaliadoNome =
              state.uri.queryParameters['avaliadoNome'] ?? 'Usuário';
          final avaliadoFoto = state.uri.queryParameters['avaliadoFoto'];
          final aluguelId = state.uri.queryParameters['aluguelId'];
          final itemId = state.uri.queryParameters['itemId'];
          final itemNome = state.uri.queryParameters['itemNome'];
          final isObrigatoria =
              state.uri.queryParameters['isObrigatoria'] == 'true';
          final avaliacaoPendenteId =
              state.uri.queryParameters['avaliacaoPendenteId'];

          if (avaliadoId == null || aluguelId == null) {
            return const Scaffold(
              body: Center(child: Text("IDs inválidos para avaliação")),
            );
          }

          return AvaliacaoPage(
            avaliadoId: avaliadoId,
            avaliadoNome: avaliadoNome,
            avaliadoFoto: avaliadoFoto,
            aluguelId: aluguelId,
            itemId: itemId,
            itemNome: itemNome,
            isObrigatoria: isObrigatoria,
            avaliacaoPendenteId: avaliacaoPendenteId,
          );
        },
      ),
    ],
  );
});

/// Provider que gerencia a integração de deep links de pagamento com a navegação
/// Inicializa o listener de deep links e redireciona automaticamente
final paymentDeepLinkNavigationProvider = FutureProvider<void>((ref) async {
  final deepLinkService = ref.watch(paymentDeepLinkServiceProvider);
  final router = ref.watch(appRouterProvider);

  deepLinkService.initialize(
    onPaymentResult: (result) {
      if (result.isSuccess && result.externalReference != null) {
        final refParts = result.externalReference!.split(',');
        final id = refParts.first.trim();
        final tipo =
            refParts.length > 1 ? refParts[1].trim().toLowerCase() : '';
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            if (tipo == 'aluguel' || tipo == 'caucao') {
              final routePath = '${AppRoutes.statusAluguel}/$id';
              router.go(routePath, extra: {
                'aluguelId': id,
                'paymentId': result.paymentId,
                'collectionStatus': result.collectionStatus,
                'fromDeepLink': true,
              });
            } else if (tipo == 'venda') {
              final routePath = '/acompanhamento-venda/$id';
              router.go(routePath, extra: {
                'vendaId': id,
                'paymentId': result.paymentId,
                'collectionStatus': result.collectionStatus,
                'fromDeepLink': true,
              });
            }
          } catch (e, stackTrace) {
            debugPrint('Erro ao navegar para acompanhamento: $e');
          }
        });
      } else if (result.isFailure) {
        try {
          final context = router.routerDelegate.navigatorKey.currentContext;
          if (context != null) {
            SnackBarUtils.mostrarErro(
                context, 'Pagamento rejeitado. Tente novamente.');
          }
        } catch (e) {
          // Erro ao mostrar snackbar
        }
      } else if (result.isPending) {
        // ⏳ Pagamento pendente
        try {
          final context = router.routerDelegate.navigatorKey.currentContext;
          if (context != null) {
            SnackBarUtils.mostrarInfo(
                context, 'Pagamento pendente. Verifique seu email.');
          }
        } catch (e) {
          // Erro ao mostrar snackbar
        }
      }
    },
  );
});
