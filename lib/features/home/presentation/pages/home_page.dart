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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Saudação
                        authState.when(
                          data: (usuario) => Text(
                            'Olá, ${usuario?.nome.split(' ').first ?? 'Usuário'}! 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => Text(
                            'Olá! 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          error: (_, __) => Text(
                            'Olá! 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Alugue ou compre itens incríveis perto de você',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.buscar),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              'Buscar furadeira, bike, cadeira...',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tabs para filtrar
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      onTap: (index) {
                        // Atualiza o estado do provider ao clicar na tab
                        final notifier =
                            ref.read(homeTabFilterProvider.notifier);
                        switch (index) {
                          case 0:
                            notifier.state = null; // Todos
                            break;
                          case 1:
                            notifier.state = TipoItem.aluguel;
                            break;
                          case 2:
                            notifier.state = TipoItem.venda;
                            break;
                        }
                      },
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      tabs: const [
                        Tab(text: 'Todos'),
                        Tab(text: 'Aluguel'),
                        Tab(text: 'Venda'),
                      ],
                    ),
                  ],
                ),
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
