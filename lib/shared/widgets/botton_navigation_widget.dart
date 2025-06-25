import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/features/chat/presentation/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BottonNavigation extends ConsumerWidget {
  const BottonNavigation({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsNaoLidos = ref.watch(numeroChatsNaoLidosProvider);
    
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            label: 'Conversas',
            icon: Badge(
              label: Text('$chatsNaoLidos'),
              isLabelVisible: chatsNaoLidos > 0,
              child: const Icon(Icons.chat_bubble_outline),
            ),
            activeIcon: Badge(
              label: Text('$chatsNaoLidos'),
              isLabelVisible: chatsNaoLidos > 0,
              child: const Icon(Icons.chat_bubble),
            ),
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_outlined),
            activeIcon: Icon(Icons.menu),
            label: 'Mais',
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
    if (location.startsWith(AppRoutes.menu)) return 4;
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
        GoRouter.of(context).go(AppRoutes.menu);
        break;
    }
  }
}