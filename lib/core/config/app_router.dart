import 'package:coisarapida/features/alugueis/presentation/pages/solicitacoes_aluguel_page.dart';
import 'package:coisarapida/features/alugueis/presentation/pages/solicitar_aluguel_page.dart';
import 'package:coisarapida/features/avaliacoes/presentation/pages/avaliacao_page.dart';
import 'package:coisarapida/features/chat/presentation/pages/lista_chat_page.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
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
            path: AppRoutes.listaChats,
            name: 'lista-chats-shell',
            builder: (context, state) => const ListaChatsPage(),
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
      // A rota principal de lista de chats agora está dentro do ShellRoute.
      // Se você precisar de uma rota de lista de chats fora do Shell, pode mantê-la aqui.
      // GoRoute(
      //   path: AppRoutes.listaChats, // Exemplo: /chats-fora-do-shell
      //   name: 'lista-chats-global',
      //   builder: (context, state) => const ListaChatsPage(),
      // ),
      GoRoute(
        path: '${AppRoutes.chat}/:chatParam', // Ex: /chat/chat_OTHERUSERID ou /chat/CHATDOCUMENTID_OTHERUSERID
        name: 'chat',
        builder: (context, state) {
          String chatParam = state.pathParameters['chatParam'] ?? '';
          String chatId = chatParam; // Por padrão, o chatParam é o chatId
          String otherUserId = '';

          // Lógica para extrair otherUserId se o chatParam tiver um formato específico
          // Exemplo: se o formato for "chat_OTHERUSERID"
          if (chatParam.startsWith('chat_')) {
            otherUserId = chatParam.substring('chat_'.length);
            // Neste caso, o chatId pode ser o próprio chatParam ou você pode ter outra lógica para obtê-lo
            // Se o chatId é o mesmo que "chat_OTHERUSERID", então chatId = chatParam;
          }
          return ChatPage(otherUserId, chatId: chatId);
        },
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

      // alugueis
      GoRoute(
        path: AppRoutes.solicitarAluguel,
        name: 'solicitar-aluguel',
        builder: (context, state) {
          final item = state.extra as Item?;
          if (item == null) {
            return const Scaffold(body: Center(child: Text("Item não fornecido para solicitação.")));
          }
          return SolicitarAluguelPage(item: item);
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

      GoRoute(
        path: AppRoutes.solicitacoesAluguel,
        name: 'solicitacoes-aluguel',
        builder: (context, state) => const SolicitacoesAluguelPage(),
      ),
      
      // Avaliação
      GoRoute(
        path: AppRoutes.avaliacao, // Usará query parameters: /avaliacao?avaliadoId=xxx&aluguelId=yyy
        name: AppRoutes.avaliacao,
        builder: (context, state) {
          final avaliadoId = state.uri.queryParameters['avaliadoId'];
          final aluguelId = state.uri.queryParameters['aluguelId'];
          final itemId = state.uri.queryParameters['itemId']; // Lendo itemId
          if (avaliadoId == null || aluguelId == null) {
            // Idealmente, redirecionar para uma página de erro ou home
            return const Scaffold(body: Center(child: Text("IDs inválidos para avaliação")));
          }
          return AvaliacaoPage(
            avaliadoId: avaliadoId,
            aluguelId: aluguelId,
            itemId: itemId, // Passando itemId para AvaliacaoPage
          );
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
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
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
    if (location.startsWith(AppRoutes.listaChats)) return 3;
    if (location.startsWith(AppRoutes.perfil)) return 4;
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
        GoRouter.of(context).go(AppRoutes.listaChats);
        break;
      case 4:
        GoRouter.of(context).go(AppRoutes.perfil);
        break;
    }
  }
}
