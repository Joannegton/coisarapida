import 'package:coisarapida/features/favoritos/providers/favoritos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final favoritosState = ref.watch(itensFavoritosProvider);
    
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: theme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
          statusBarIconBrightness: theme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
        ),
        title: const Text('Meus Favoritos'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, size: screenWidth * 0.06),
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
        children: [          Container(
            height: screenWidth * 0.15,
            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
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
          
          Expanded(
            child: favoritosState.when(
              data: (itens) {
                final itensFiltrados = _filtrarItens(itens);
                
                if (itensFiltrados.isEmpty) {
                  return _buildEstadoVazio();
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(itensFavoritosProvider);
                    await ref.read(itensFavoritosProvider.future);
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(screenWidth * 0.04),
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.only(right: screenWidth * 0.02),
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
          fontSize: screenWidth * 0.03,
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ThemeData theme, Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.detalhesItem}/${item['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.03),
          child: Row(
            children: [
              // Imagem do item
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: screenWidth * 0.2,
                  height: screenWidth * 0.2,
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
                          size: screenWidth * 0.08,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
              ),
              
              SizedBox(width: screenWidth * 0.03),
              
              // Informações do item
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nome'] ?? 'Item sem nome',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.045,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      'Por ${item['proprietarioNome']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: screenWidth * 0.035,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: screenWidth * 0.005),
                        Text(
                          '${item['distancia']?.toStringAsFixed(1) ?? '0.0'} km',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Icon(
                          Icons.star,
                          size: screenWidth * 0.035,
                          color: Colors.orange,
                        ),
                        SizedBox(width: screenWidth * 0.005),
                        Text(
                          '${item['avaliacao']?.toStringAsFixed(1) ?? '0.0'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.035,
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
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  Text(
                    'por dia',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015, vertical: screenWidth * 0.005),
                        decoration: BoxDecoration(
                          color: item['disponivel'] == true ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['disponivel'] == true ? 'Disponível' : 'Indisponível',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.025,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      // Remover dos favoritos
                      GestureDetector(
                        onTap: () => _removerFavorito(item['id']),
                        child: Container(
                          padding: EdgeInsets.all(screenWidth * 0.01),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: screenWidth * 0.04,
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: screenWidth * 0.2,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: screenWidth * 0.06),
            Text(
              'Nenhum favorito ainda',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.055,
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            Text(
              'Explore itens incríveis e adicione aos seus favoritos para encontrá-los facilmente depois!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade500,
                fontSize: screenWidth * 0.04,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth * 0.08),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.buscar),
              icon: Icon(Icons.search, size: screenWidth * 0.05),
              label: Text('Explorar Itens', style: TextStyle(fontSize: screenWidth * 0.04)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenWidth * 0.03),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoErro(String erro) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: screenWidth * 0.16, color: Colors.red),
            SizedBox(height: screenWidth * 0.04),
            Text('Erro ao carregar favoritos: $erro', style: TextStyle(fontSize: screenWidth * 0.04)),
            SizedBox(height: screenWidth * 0.04),
            ElevatedButton(
              onPressed: () => ref.refresh(itensFavoritosProvider),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenWidth * 0.03),
              ),
              child: Text('Tentar Novamente', style: TextStyle(fontSize: screenWidth * 0.04)),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover dos Favoritos'),
        content: const Text('Tem certeza que deseja remover este item dos seus favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref.read(favoritosProvider.notifier).removerFavorito(itemId);
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
