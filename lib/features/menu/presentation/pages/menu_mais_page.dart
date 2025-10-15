import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/menu/presentation/widgets/cabecalho_perfil_widget.dart';
import 'package:coisarapida/features/menu/presentation/widgets/configuracoes_rapidas.dart';
import 'package:coisarapida/features/menu/presentation/widgets/menu_list_tile_widget.dart';
import 'package:coisarapida/features/menu/presentation/widgets/minhas_estatistica_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MenuMaisPage extends ConsumerWidget {
  const MenuMaisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioAtualStreamProvider).value;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    if (usuario == null) {
      context.go(AppRoutes.login);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: screenWidth * 0.15,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.primary,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(screenWidth * 0.075),
              child: CabecalhoPerfilWidget(usuario: usuario!),
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
              // Notificações não vistas (indicadas pela bolinha vermelha)
              MenuListTile(
                icone: Icons.notifications_outlined,
                texto: 'Notificações',
                onTap: () => context.push(AppRoutes.notificacoes),
                iconeAcao: const Icon(Icons.circle, color: Color.fromARGB(255, 231, 16, 1), size: 12),
              ),
              const Divider(height: 1),
              MenuListTile(
                icone: Icons.settings_outlined,
                texto: 'Configurações',
                onTap: () => context.push(AppRoutes.configuracoes),
                iconeAcao: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
              const Divider(height: 1),
              
              // Seção de Verificações Opcionais
              Padding(
                padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenWidth * 0.06, screenWidth * 0.04, screenWidth * 0.02),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Verificações Opcionais',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              MenuListTile(
                icone: Icons.phone_android,
                texto: usuario.telefoneVerificado ? 'Telefone Verificado ✓' : 'Verificar Telefone',
                onTap: () => context.push(AppRoutes.verificacaoTelefone),
                iconeAcao: Icon(
                  usuario.telefoneVerificado ? Icons.check_circle : Icons.arrow_forward_ios,
                  size: 20,
                  color: usuario.telefoneVerificado ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Divider(height: 1),
              MenuListTile(
                icone: Icons.home,
                texto: usuario.enderecoVerificado ? 'Residência Verificada ✓' : 'Verificar Residência',
                onTap: () => context.push(AppRoutes.verificacaoResidencia),
                iconeAcao: Icon(
                  usuario.enderecoVerificado ? Icons.check_circle : Icons.arrow_forward_ios,
                  size: 20,
                  color: usuario.enderecoVerificado ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Divider(height: 1),
              
              SizedBox(height: screenWidth * 0.04),
              MinhasEstatisticaWidget(usuario: usuario),
              const ConfiguracoesRapidas()
            ]),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
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
                    minimumSize: Size.fromHeight(screenWidth * 0.09),
                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
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