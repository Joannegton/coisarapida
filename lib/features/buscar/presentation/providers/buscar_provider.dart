import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/home/presentation/providers/itens_provider.dart';
import 'package:coisarapida/features/buscar/presentation/controllers/buscarPage_controller.dart';

/// Provider que aplica todos os filtros da página de busca
final itensFiltradosBuscaProvider = Provider<List<Map<String, dynamic>>>((ref) {
  // Obtém o estado dos filtros do controller
  final filtros = ref.watch(buscarPageControllerProvider);
  
  // Obtém os itens base (já ordenados por distância)
  List<Map<String, dynamic>> itensBase;
  
  if (filtros.termoBusca.trim().isNotEmpty) {
    // Se há termo de busca, usa o provider de busca por termo
    itensBase = ref.watch(itensPeloTermoProvider(filtros.termoBusca));
  } else {
    // Caso contrário, usa todos os itens próximos
    itensBase = ref.watch(todosItensProximosProvider);
  }

  if (itensBase.isEmpty) return [];

  // Aplica os filtros avançados
  var itensFiltrados = itensBase.where((itemMap) {
    final item = itemMap['item'] as Item;
    final distancia = itemMap['distancia'] as double?;

    // Filtro por categoria - só filtra se não for 'todos'
    if (filtros.categoriaSelecionada != null && 
        filtros.categoriaSelecionada != 'todos' && 
        !item.categoria.toLowerCase().contains(filtros.categoriaSelecionada!.toLowerCase())) {
      return false;
    }

    // Filtro por disponibilidade - só filtra se ativado
    if (filtros.apenasDisponiveis && !item.disponivel) {
      return false;
    }

    // Filtro por distância - só filtra se distância for conhecida
    if (distancia != null && distancia > filtros.distanciaMaxima) {
      return false;
    }

    // Filtro por preço
    final preco = item.precoPorDia;
    if (preco < filtros.faixaPreco.start || preco > filtros.faixaPreco.end) {
      return false;
    }

    // Filtro por avaliação
    if (item.avaliacao < filtros.avaliacaoMinima) {
      return false;
    }

    return true;
  }).toList();

  // Aplica ordenação
  switch (filtros.ordenarPor) {
    case 'distancia':
      // Já está ordenado por distância, mantém a ordem
      break;
    
    case 'preco_menor':
      itensFiltrados.sort((a, b) {
        final itemA = a['item'] as Item;
        final itemB = b['item'] as Item;
        return itemA.precoPorDia.compareTo(itemB.precoPorDia);
      });
      break;
    
    case 'preco_maior':
      itensFiltrados.sort((a, b) {
        final itemA = a['item'] as Item;
        final itemB = b['item'] as Item;
        return itemB.precoPorDia.compareTo(itemA.precoPorDia);
      });
      break;
    
    case 'avaliacao':
      itensFiltrados.sort((a, b) {
        final itemA = a['item'] as Item;
        final itemB = b['item'] as Item;
        return itemB.avaliacao.compareTo(itemA.avaliacao);
      });
      break;
  }

  return itensFiltrados;
});
