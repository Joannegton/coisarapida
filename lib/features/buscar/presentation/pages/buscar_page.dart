import 'package:coisarapida/features/buscar/presentation/controllers/buscarPage_controller.dart';
import 'package:coisarapida/features/buscar/presentation/providers/buscar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/providers/itens_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../itens/domain/entities/item.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Tela de busca avançada com filtros
class BuscarPage extends ConsumerStatefulWidget {
  const BuscarPage({super.key});

  @override
  ConsumerState<BuscarPage> createState() => _BuscarPageState();
}

class _BuscarPageState extends ConsumerState<BuscarPage> {
  final _buscaController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Verificar se veio do botão de busca do home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final fromHome = uri.queryParameters['fromHome'] == 'true';
      if (fromHome) {
        _focusNode.requestFocus();
      }
    });
    
    _buscaController.addListener(() {
      ref.read(buscarPageControllerProvider.notifier).setTermoBusca(_buscaController.text);
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itensAsyncValue = ref.watch(todosItensStreamProvider);
    final itensFiltrados = ref.watch(itensFiltradosBuscaProvider);
    final filtros = ref.watch(buscarPageControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Itens', style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        )),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de busca e filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.05).round()),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Campo de busca
                TextField(
                  controller: _buscaController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou descrição...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _buscaController.clear();
                          },
                        ),
                        // IconButton(
                        //   icon: const Icon(Icons.tune),
                        //   onPressed: _mostrarFiltrosAvancados,
                        // ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Filtros rápidos
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroRapido('Todos', filtros.categoriaSelecionada == 'todos', () {
                        ref.read(buscarPageControllerProvider.notifier).setCategoria('todos');
                      }),
                      _buildFiltroRapido('Ferramentas', filtros.categoriaSelecionada == 'ferramentas', () {
                        ref.read(buscarPageControllerProvider.notifier).setCategoria('ferramentas');
                      }),
                      _buildFiltroRapido('Eletrônicos', filtros.categoriaSelecionada == 'eletronicos', () {
                        ref.read(buscarPageControllerProvider.notifier).setCategoria('eletronicos');
                      }),
                      _buildFiltroRapido('Esportes', filtros.categoriaSelecionada == 'esportes', () {
                        ref.read(buscarPageControllerProvider.notifier).setCategoria('esportes');
                      }),
                      _buildFiltroRapido('Casa', filtros.categoriaSelecionada == 'casa', () {
                        ref.read(buscarPageControllerProvider.notifier).setCategoria('casa');
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Barra de ordenação
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Ordenar por:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChipOrdenacao('Distância', 'distancia'),
                        _buildChipOrdenacao('Menor Preço', 'preco_menor'),
                        _buildChipOrdenacao('Maior Preço', 'preco_maior'),
                        _buildChipOrdenacao('Melhor Avaliado', 'avaliacao'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de resultados
          Expanded(
            child: itensAsyncValue.when(
              data: (_) {
                if (itensFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum item encontrado',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tente ajustar os filtros ou buscar por outro termo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: itensFiltrados.length,
                  itemBuilder: (context, index) => _buildItemListTile(
                    context,
                    theme,
                    itensFiltrados[index],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
        ],
      ),
    );
  }

  Widget _buildFiltroRapido(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => onTap(),
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

  Widget _buildChipOrdenacao(String label, String valor) {
    final filtros = ref.watch(buscarPageControllerProvider);
    final isSelected = filtros.ordenarPor == valor;
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) {
          ref.read(buscarPageControllerProvider.notifier).setOrdenarPor(valor);
        },
        label: Text(label),
        backgroundColor: isSelected ? theme.colorScheme.secondary : null,
        selectedColor: theme.colorScheme.secondary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildItemListTile(BuildContext context, ThemeData theme, Map<String, dynamic> itemMap) {
    final item = itemMap['item'] as Item;
    final distancia = itemMap['distancia'] as double?;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.18; // 18% da largura da tela para a imagem
    final padding = screenWidth * 0.03; // 3% para padding

    return Card(
      margin: EdgeInsets.only(bottom: padding),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.detalhesItem}/${item.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            children: [
              // Imagem do item
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    image: item.fotos.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.fotos[0]),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item.fotos.isEmpty
                      ? Icon(
                          Icons.image,
                          size: imageSize * 0.4, // 40% do tamanho da imagem
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
              ),
              
              SizedBox(width: padding),
              
              // Informações do item
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nome,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.categoria.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
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
                        Expanded(
                          child: Text(
                            distancia != null ? '${distancia.toStringAsFixed(1)} km' : item.localizacao.cidade,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width:2),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.avaliacao.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16), // Espaço moderado para separar da coluna de preço/status
                      ],
                    ),
                  ],
                ),
              ),
              
              // Preço
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getPrecoDisplay(item),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.disponivel ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.disponivel ? 'Disponível' : 'Indisponível',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarFiltrosAvancados() {
    final filtros = ref.read(buscarPageControllerProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtros Avançados',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Distância
                    Text('Distância máxima: ${filtros.distanciaMaxima.toInt()} km'),
                    Slider(
                      value: filtros.distanciaMaxima,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      onChanged: (value) {
                        ref.read(buscarPageControllerProvider.notifier).setDistanciaMaxima(value);
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Faixa de preço
                    Text('Faixa de preço: R\$ ${filtros.faixaPreco.start.toInt()} - R\$ ${filtros.faixaPreco.end.toInt()}'),
                    RangeSlider(
                      values: filtros.faixaPreco,
                      min: 0,
                      max: 1000,
                      divisions: 100,
                      onChanged: (values) {
                        ref.read(buscarPageControllerProvider.notifier).setFaixaPreco(values);
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Avaliação mínima
                    Text('Avaliação mínima: ${filtros.avaliacaoMinima.toStringAsFixed(1)} estrelas'),
                    Slider(
                      value: filtros.avaliacaoMinima,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      onChanged: (value) {
                        ref.read(buscarPageControllerProvider.notifier).setAvaliacaoMinima(value);
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Apenas disponíveis
                    SwitchListTile(
                      title: const Text('Apenas itens disponíveis'),
                      value: filtros.apenasDisponiveis,
                      onChanged: (value) {
                        ref.read(buscarPageControllerProvider.notifier).setApenasDisponiveis(value);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Row(
              //   children: [
              //     Expanded(
              //       child: OutlinedButton(
              //         onPressed: _limparFiltros,
              //         child: const Text('Limpar'),
              //       ),
              //     ),
              //     const SizedBox(width: 12),
              //     Expanded(
              //       child: ElevatedButton(
              //         onPressed: () {
              //           Navigator.of(context).pop();
              //           _aplicarFiltros();
              //         },
              //         child: const Text('Aplicar'),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }


  void _limparFiltros() {
    // Limpa todos os filtros usando o controller
    ref.read(buscarPageControllerProvider.notifier).limparFiltros();
    _buscaController.clear();
    SnackBarUtils.mostrarSucesso(context, 'Filtros limpos!');
  }

  String _getPrecoDisplay(Item item) {
    // Se é só venda, mostra preço de venda
    if (item.tipo == TipoItem.venda && item.precoVenda != null) {
      return 'R\$ ${item.precoVenda!.toStringAsFixed(2)}';
    }
    // Se é ambos ou aluguel, mostra preço de aluguel por dia
    if (item.tipo == TipoItem.aluguel || item.tipo == TipoItem.ambos) {
      return 'R\$ ${item.precoPorDia.toStringAsFixed(2)}/dia';
    }
    // Fallback para o preço de aluguel caso algo não esteja configurado
    return 'R\$ ${item.precoPorDia.toStringAsFixed(2)}/dia';
  }
}
