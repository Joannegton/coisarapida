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
  String _categoriaSelecionada = 'todos';
  double _distanciaMaxima = 10.0;
  RangeValues _faixaPreco = const RangeValues(0, 100);
  double _avaliacaoMinima = 0.0;
  bool _apenasDisponiveis = true;
  String _ordenarPor = 'distancia';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itensState = ref.watch(itensProximosProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Itens'),
        backgroundColor: theme.colorScheme.surface,
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
                            _buscarItens('');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: _mostrarFiltrosAvancados,
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _buscarItens,
                ),
                
                const SizedBox(height: 12),
                
                // Filtros rápidos
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroRapido('Todos', _categoriaSelecionada == 'todos', () {
                        setState(() => _categoriaSelecionada = 'todos');
                      }),
                      _buildFiltroRapido('Ferramentas', _categoriaSelecionada == 'ferramentas', () {
                        setState(() => _categoriaSelecionada = 'ferramentas');
                      }),
                      _buildFiltroRapido('Eletrônicos', _categoriaSelecionada == 'eletronicos', () {
                        setState(() => _categoriaSelecionada = 'eletronicos');
                      }),
                      _buildFiltroRapido('Esportes', _categoriaSelecionada == 'esportes', () {
                        setState(() => _categoriaSelecionada = 'esportes');
                      }),
                      _buildFiltroRapido('Casa', _categoriaSelecionada == 'casa', () {
                        setState(() => _categoriaSelecionada = 'casa');
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
                        _buildChipOrdenacao('Mais Recente', 'recente'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de resultados
          Expanded(
            child: itensState.when(
              data: (itens) {
                final itensFiltrados = _filtrarItens(itens);
                
                if (itensFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum item encontrado',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tente ajustar os filtros ou buscar por outros termos',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
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
                      onPressed: () => ref.refresh(itensProximosProvider),
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
    final isSelected = _ordenarPor == valor;
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) {
          setState(() => _ordenarPor = valor);
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

  Widget _buildItemListTile(BuildContext context, ThemeData theme, Item item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.detalhesItem}/${item.id}'),
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
                        Text(
                          // TODO: Calcular e exibir a distância real
                          item.localizacao.cidade, // Exemplo, idealmente seria a distância
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
                          item.avaliacao.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
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
                    'R\$ ${item.precoPorDia.toStringAsFixed(2)}',
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
                    Text('Distância máxima: ${_distanciaMaxima.toInt()} km'),
                    Slider(
                      value: _distanciaMaxima,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      onChanged: (value) {
                        setState(() => _distanciaMaxima = value);
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Faixa de preço
                    Text('Faixa de preço: R\$ ${_faixaPreco.start.toInt()} - R\$ ${_faixaPreco.end.toInt()}'),
                    RangeSlider(
                      values: _faixaPreco,
                      min: 0,
                      max: 500,
                      divisions: 50,
                      onChanged: (values) {
                        setState(() => _faixaPreco = values);
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Avaliação mínima
                    Text('Avaliação mínima: ${_avaliacaoMinima.toStringAsFixed(1)} estrelas'),
                    Slider(
                      value: _avaliacaoMinima,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() => _avaliacaoMinima = value);
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Apenas disponíveis
                    SwitchListTile(
                      title: const Text('Apenas itens disponíveis'),
                      value: _apenasDisponiveis,
                      onChanged: (value) {
                        setState(() => _apenasDisponiveis = value);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _limparFiltros,
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _aplicarFiltros();
                      },
                      child: const Text('Aplicar'),
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

  List<Item> _filtrarItens(List<Item> itens) {
    var itensFiltrados = itens.where((item) {
      // Filtro por categoria
      if (_categoriaSelecionada != 'todos' && item.categoria != _categoriaSelecionada) {
        return false;
      }
      
      // Filtro por disponibilidade
      if (_apenasDisponiveis && !item.disponivel) {
        return false;
      }
      
      // Filtro por distância
      // TODO: Implementar cálculo de distância real e filtro
      // if (calcularDistancia(item.localizacao) > _distanciaMaxima) {
      //   return false;
      // }
      
      // Filtro por preço
      final preco = item.precoPorDia;
      if (preco < _faixaPreco.start || preco > _faixaPreco.end) {
        return false;
      }
      
      // Filtro por avaliação
      if (item.avaliacao < _avaliacaoMinima) {
        return false;
      }
      
      // Filtro por busca
      if (_buscaController.text.isNotEmpty) {
        final termo = _buscaController.text.toLowerCase();
        final nome = item.nome.toLowerCase();
        final descricao = item.descricao.toLowerCase();
        
        if (!nome.contains(termo) && !descricao.contains(termo)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Ordenação
    switch (_ordenarPor) {
      case 'distancia':
        // TODO: Ordenar por distância real quando implementado
        // itensFiltrados.sort((a, b) => calcularDistancia(a.localizacao).compareTo(calcularDistancia(b.localizacao)));
        break;
      case 'preco_menor':
        itensFiltrados.sort((a, b) => a.precoPorDia.compareTo(b.precoPorDia));
        break;
      case 'preco_maior':
        itensFiltrados.sort((a, b) => b.precoPorDia.compareTo(a.precoPorDia));
        break;
      case 'avaliacao':
        itensFiltrados.sort((a, b) => b.avaliacao.compareTo(a.avaliacao));
        break;
    }
    
    return itensFiltrados;
  }

  void _buscarItens(String termo) {
    setState(() {}); // Trigger rebuild para aplicar filtro
  }

  void _aplicarFiltros() {
    setState(() {}); // Trigger rebuild para aplicar filtros
    SnackBarUtils.mostrarSucesso(context, 'Filtros aplicados!');
  }

  void _limparFiltros() {
    setState(() {
      _categoriaSelecionada = 'todos';
      _distanciaMaxima = 10.0;
      _faixaPreco = const RangeValues(0, 100);
      _avaliacaoMinima = 0.0;
      _apenasDisponiveis = true;
      _ordenarPor = 'distancia';
      _buscaController.clear();
    });
  }
}
