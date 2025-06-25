import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/menu/presentation/widgets/cabecalho_perfil_widget.dart';
import 'package:coisarapida/features/menu/presentation/widgets/menu_list_tile_widget.dart';
import 'package:coisarapida/features/menu/presentation/widgets/minhas_estatistica_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MenuMaisPage extends ConsumerWidget {
  const MenuMaisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioAtualStreamProvider).value!;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.primary,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(30), 
              child: CabecalhoPerfilWidget(usuario: usuario),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              MenuListTile(
                icone: Icons.favorite_outline,
                texto: 'Favoritos',
                onTap: () => context.push(AppRoutes.favoritos),
              ),
              const Divider(height: 1),
              MenuListTile(
                icone: Icons.notifications_outlined,
                texto: 'Notificações',
                onTap: () {},
                iconeAcao: const Icon(Icons.circle, color: Color.fromARGB(255, 231, 16, 1), size: 12),
              ),
              const Divider(height: 1),
              MenuListTile(
                icone: Icons.privacy_tip_outlined,
                texto: 'Privacidade',
                onTap: () {},
              ),
              const Divider(height: 1),
              MenuListTile(
                icone: Icons.help_outline,
                texto: 'Suporte',
                onTap: () {},
              ),
              const Divider(height: 1),
              MenuListTile(
                icone: Icons.account_balance_wallet_outlined,
                texto: 'Saldo em conta',
                onTap: () {},
                iconeAcao: Text(
                  'R\$ 150,00',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),
              MinhasEstatisticaWidget(usuario: usuario),
            ]),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarLogout(context, ref),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Sair da Conta',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(35),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                ),
              ),
            ),
        ]
      ),
    );
  }

  void _confirmarLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

}