import 'package:coisarapida/features/home/presentation/providers/home_provider.dart';
import 'package:coisarapida/features/home/presentation/providers/itens_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../autenticacao/presentation/providers/auth_provider.dart';

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
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(usuarioAtualStreamProvider);
    final tipoFiltro = ref.watch(homeTabFilterProvider);
    final itensAsyncValue = ref.watch(itensProximosProvider);
    final itensFiltrados = ref.watch(itensFiltradosProvider(tipoFiltro));

    return Scaffold(
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
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            setState(() {
              _scrollOffset = notification.metrics.pixels;
            });
          }
          return false;
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
          SliverAppBar(
            expandedHeight: 170,
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // Calcular a opacidade baseada no quanto o AppBar está expandido
                final expandRatio = (constraints.maxHeight - kToolbarHeight) / 
                    (170 - kToolbarHeight);
                final opacity = expandRatio.clamp(0.0, 1.0);
                
                return FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                        child: Opacity(
                          opacity: opacity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Saudação
                              authState.when(
                                data: (usuario) => Text(
                                  'Olá, ${usuario?.nome.split(' ').first ?? 'Usuário'}!',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                loading: () => Text(
                                  'Olá!',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                error: (_, __) => Text(
                                  'Olá!',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Alugue ou compre itens incríveis perto de você',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Builder(
                builder: (context) {
                  // Calcular o espaçamento baseado no scroll offset
                  final maxScroll = 170 - kToolbarHeight; // expandedHeight - toolbarHeight
                  final scrollProgress = (_scrollOffset / maxScroll).clamp(0.0, 1.0);
                  final spacing = scrollProgress < 0.5 ? 2.0 : 0.0; // 2 quando expandido, 0 quando colapsado

                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('${AppRoutes.buscar}?fromHome=true'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12
                            ),
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
                                  'Buscar furadeira, bike, cadeira...',
                                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: spacing),
                        // Tabs para filtrar
                        TabBar(
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Categorias populares
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                    height: 80,
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
              // Usamos a lista filtrada abaixo, o `_` ignora a lista completa
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7, // Ajuste para caber melhor os badges
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ItemCard(item: itensFiltrados[index]),
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
                        onPressed: () => ref.refresh(itensProximosProvider),
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
