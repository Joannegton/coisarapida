import 'package:coisarapida/core/utils/verificacao_helper.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/status_endereco.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/home/presentation/providers/home_provider.dart';
import 'package:coisarapida/features/home/presentation/providers/itens_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../widgets/categoria_card.dart';
import '../widgets/item_card.dart';

/// Tela principal - busca e descoberta de itens para aluguel
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final tipo = switch (_tabController.index) {
      0 => null, // Todos
      1 => TipoItem.aluguel,
      2 => TipoItem.venda,
      _ => null,
    };
    ref.read(homeTabFilterProvider.notifier).state = tipo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tipoFiltro = ref.watch(homeTabFilterProvider);
    final itensAsyncValue = ref.watch(todosItensStreamProvider);
    final itensFiltrados = tipoFiltro == null 
        ? ref.watch(todosItensProximosProvider)
        : ref.watch(itensPeloTipoItemProvider(tipoFiltro));

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: GestureDetector(
          onTap: () => context.push('${AppRoutes.buscar}?fromHome=true'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  'Buscar itens...',
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          labelPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Aluguel'),
            Tab(text: 'Venda'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.anunciarItem),
        icon: const Icon(Icons.add),
        label: const Text('Anunciar'),
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Banner de verificação (se necessário)
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final bannerWidget = VerificacaoHelper.bannerVerificacao(ref, context);
                if (bannerWidget != null) {
                  return GestureDetector(
                    onTap: () {
                      final authState = ref.read(usuarioAtualStreamProvider);
                      if (!authState.hasValue || authState.value == null) return;
                      
                      final usuario = authState.value!;
                      if (usuario.telefone == null || usuario.telefone!.isEmpty) {
                        context.push(AppRoutes.verificacaoTelefone);
                      } else if (usuario.statusEndereco == StatusEndereco.rejeitado || usuario.statusEndereco == null) {
                        context.push(AppRoutes.verificacaoResidencia);
                      }
                    },
                    child: bannerWidget,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Categorias populares
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8), // Reduz bottom para menos espaço
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categorias Populares',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: screenHeight * 0.12,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        CategoriaCard(
                            nome: 'Ferramentas',
                            icone: Icons.build,
                            cor: Colors.orange),
                        CategoriaCard(
                            nome: 'Eletrônicos',
                            icone: Icons.devices,
                            cor: Colors.blue),
                        CategoriaCard(
                            nome: 'Esportes',
                            icone: Icons.sports_soccer,
                            cor: Colors.green),
                        CategoriaCard(
                            nome: 'Casa',
                            icone: Icons.home,
                            cor: Colors.purple),
                        CategoriaCard(
                            nome: 'Transporte',
                            icone: Icons.directions_bike,
                            cor: Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Itens próximos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _getTituloSecao(tipoFiltro),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Grid de itens
          itensAsyncValue.when(
            data: (_) => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ItemCard(
                    item: itensFiltrados[index]['item'],
                    distancia: itensFiltrados[index]['distancia'],
                  ),
                  childCount: itensFiltrados
                      .take(6)
                      .length, // Mostrar apenas 6 itens na home
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erro ao carregar itens: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(todosItensStreamProvider),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Ver mais
          SliverToBoxAdapter( 
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.buscar),
                child: const Text('Ver Todos os Itens'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTituloSecao(TipoItem? filtro) {
    switch (filtro) {
      case TipoItem.aluguel:
        return 'Para Alugar';
      case TipoItem.venda:
        return 'Para Vender';
      default:
        return 'Perto de Você';
    }
  }
}
