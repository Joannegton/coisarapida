import 'package:coisarapida/features/favoritos/providers/favoritos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Tela de itens favoritos do usuário
class FavoritosPage extends ConsumerStatefulWidget {
  const FavoritosPage({super.key});

  @override
  ConsumerState<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends ConsumerState<FavoritosPage> {
  String _filtroCategoria = 'todos';
  String _ordenacao = 'recente';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoritosState = ref.watch(itensFavoritosProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Favoritos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _ordenacao = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recente',
                child: Text('Mais recentes'),
              ),
              const PopupMenuItem(
                value: 'preco_menor',
                child: Text('Menor preço'),
              ),
              const PopupMenuItem(
                value: 'preco_maior',
                child: Text('Maior preço'),
              ),
              const PopupMenuItem(
                value: 'distancia',
                child: Text('Mais próximos'),
              ),
              const PopupMenuItem(
                value: 'avaliacao',
                child: Text('Melhor avaliados'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros por categoria
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFiltroChip('todos', 'Todos'),
                _buildFiltroChip('ferramentas', 'Ferramentas'),
                _buildFiltroChip('eletronicos', 'Eletrônicos'),
                _buildFiltroChip('esportes', 'Esportes'),
                _buildFiltroChip('casa', 'Casa'),
                _buildFiltroChip('transporte', 'Transporte'),
                _buildFiltroChip('eventos', 'Eventos'),
              ],
            ),
          ),
          
          // Lista de favoritos
          Expanded(
            child: favoritosState.when(
              data: (itens) {
                final itensFiltrados = _filtrarItens(itens);
                
                if (itensFiltrados.isEmpty) {
                  return _buildEstadoVazio();
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    // Invalida o provider para forçar uma nova busca.
                    ref.invalidate(itensFavoritosProvider);
                    // Aguarda o novo futuro do provider para o RefreshIndicator.
                    await ref.read(itensFavoritosProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: itensFiltrados.length,
                    itemBuilder: (context, index) => _buildItemCard(
                      context,
                      theme,
                      itensFiltrados[index],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildEstadoErro(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String categoria, String label) {
    final isSelected = _filtroCategoria == categoria;
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) {
          setState(() => _filtroCategoria = categoria);
        },
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

  Widget _buildItemCard(BuildContext context, ThemeData theme, Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.detalhesItem}/${item['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagem do item
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
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
                          size: 32,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Informações do item
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nome'] ?? 'Item sem nome',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Por ${item['proprietarioNome']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${item['distancia']?.toStringAsFixed(1) ?? '0.0'} km',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.star,
                          size: 14,
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
              
              // Preço e ações
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${item['precoPorDia']?.toStringAsFixed(2) ?? '0,00'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'por dia',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item['disponivel'] == true ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['disponivel'] == true ? 'Disponível' : 'Indisponível',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Remover dos favoritos
                      GestureDetector(
                        onTap: () => _removerFavorito(item['id']),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoVazio() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum favorito ainda',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Explore itens incríveis e adicione aos seus favoritos para encontrá-los facilmente depois!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.buscar),
              icon: const Icon(Icons.search),
              label: const Text('Explorar Itens'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoErro(String erro) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro ao carregar favoritos: $erro'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(itensFavoritosProvider),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filtrarItens(List<Map<String, dynamic>> itens) {
    var itensFiltrados = itens.where((item) {
      if (_filtroCategoria != 'todos' && item['categoria'] != _filtroCategoria) {
        return false;
      }
      return true;
    }).toList();
    
    // Ordenação
    switch (_ordenacao) {
      case 'preco_menor':
        itensFiltrados.sort((a, b) => (a['precoPorDia'] ?? 0).compareTo(b['precoPorDia'] ?? 0));
        break;
      case 'preco_maior':
        itensFiltrados.sort((a, b) => (b['precoPorDia'] ?? 0).compareTo(a['precoPorDia'] ?? 0));
        break;
      case 'distancia':
        itensFiltrados.sort((a, b) => (a['distancia'] ?? 0).compareTo(b['distancia'] ?? 0));
        break;
      case 'avaliacao':
        itensFiltrados.sort((a, b) => (b['avaliacao'] ?? 0).compareTo(a['avaliacao'] ?? 0));
        break;
    }
    
    return itensFiltrados;
  }

  void _removerFavorito(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover dos Favoritos'),
        content: const Text('Tem certeza que deseja remover este item dos seus favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
              onPressed: () async { // Tornar async
                Navigator.of(context).pop(); // Fechar diálogo primeiro
                try {
                  await ref.read(favoritosProvider.notifier).removerFavorito(itemId); // Await
                  SnackBarUtils.mostrarSucesso(context, 'Item removido dos favoritos');
                } catch (e) {
                  SnackBarUtils.mostrarErro(context, 'Erro ao remover favorito: ${e.toString()}');
                }
              },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
