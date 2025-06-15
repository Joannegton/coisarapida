import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../autenticacao/presentation/providers/auth_provider.dart';
import '../providers/itens_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Tela principal - busca e descoberta de itens para aluguel
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _buscaController = TextEditingController();
  String _categoriaSelecionada = 'todos';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final itensState = ref.watch(itensProximosProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com saudação
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
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
                              color: Colors.white,
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
                          'Descubra itens incríveis perto de você',
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.buscar),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      children: [
                        _buildCategoriaCard('Ferramentas', Icons.build, Colors.orange),
                        _buildCategoriaCard('Eletrônicos', Icons.devices, Colors.blue),
                        _buildCategoriaCard('Esportes', Icons.sports_soccer, Colors.green),
                        _buildCategoriaCard('Casa', Icons.home, Colors.purple),
                        _buildCategoriaCard('Transporte', Icons.directions_bike, Colors.red),
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
                'Perto de Você',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Grid de itens
          itensState.when(
            data: (itens) => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildItemCard(context, theme, itens[index]),
                  childCount: itens.take(6).length, // Mostrar apenas 6 itens na home
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.anunciarItem),
        icon: const Icon(Icons.add),
        label: const Text('Anunciar'),
        backgroundColor: theme.colorScheme.secondary,
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ThemeData theme, Map<String, dynamic> item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.detalhesItem}/${item['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do item
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  image: item['fotos'] != null && item['fotos'].isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item['fotos'][0]),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item['fotos'] == null || item['fotos'].isEmpty
                    ? Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey.shade400,
                      )
                    : null,
              ),
            ),
            
            // Informações do item
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nome'] ?? 'Item sem nome',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${item['precoPorDia']?.toStringAsFixed(2) ?? '0,00'}/dia',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${item['distancia']?.toStringAsFixed(1) ?? '0.0'} km',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${item['avaliacao']?.toStringAsFixed(1) ?? '0.0'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaCard(String nome, IconData icone, Color cor) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icone, color: cor, size: 28),
          ),
          const SizedBox(height: 8),
          Flexible( // Adicionado Flexible para o texto se ajustar ao espaço
            child: Text(
              nome,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCategoriaChip(String categoria, String label, IconData icone) {
    final isSelected = _categoriaSelecionada == categoria;
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _categoriaSelecionada = categoria;
          });
          _filtrarPorCategoria(categoria);
        },
        avatar: Icon(
          icone,
          size: 18,
          color: isSelected ? Colors.white : theme.colorScheme.primary,
        ),
        label: Text(label),
        backgroundColor: isSelected ? theme.colorScheme.primary : null,
        selectedColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontSize: 12,
        ),
      ),
    );
  }

  void _mostrarFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Distância'),
              subtitle: const Text('Até 5 km'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => SnackBarUtils.mostrarInfo(context, 'Filtro de distância em desenvolvimento'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Preço'),
              subtitle: const Text('R\$ 0 - R\$ 100'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => SnackBarUtils.mostrarInfo(context, 'Filtro de preço em desenvolvimento'),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Avaliação'),
              subtitle: const Text('4+ estrelas'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => SnackBarUtils.mostrarInfo(context, 'Filtro de avaliação em desenvolvimento'),
            ),
          ],
        ),
      ),
    );
  }

  void _buscarItens(String termo) {
    if (termo.isNotEmpty) {
      SnackBarUtils.mostrarInfo(context, 'Buscando: $termo');
      // TODO: Implementar busca real
    }
  }

  void _filtrarPorCategoria(String categoria) {
    SnackBarUtils.mostrarInfo(context, 'Filtrando por: $categoria');
    // TODO: Implementar filtro real
  }

}
