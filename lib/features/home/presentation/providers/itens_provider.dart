import 'package:coisarapida/features/itens/data/models/item_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/itens/presentation/providers/item_provider.dart'; // Para itemRepositoryProvider

/// Provider para itens próximos ao usuário
final itensProximosProvider = FutureProvider<List<Item>>((ref) async {
  final itensRepository = ref
      .watch(itemRepositoryProvider); // Corrigido para itemRepositoryProvider

  // adicionar lógica para buscar itens realmente "próximos"
  // usando a localização do usuário e queries geoespaciais.
  // Ex: return itensRepository.getItensProximos(userLat, userLng, raio);
  try {
    final List<ItemModel> itensModel = await itensRepository.getTodosItens();
    return itensModel
        .cast<Item>(); // ItemModel estende Item, então o cast é seguro.
  } catch (e) {
    // O FutureProvider lida com o estado de erro automaticamente,
    // mas você pode logar o erro aqui se desejar.
    print("Erro ao carregar itens no itensProximosProvider: $e");
    rethrow; // Importante para que o FutureProvider saiba do erro.
  }
});

final itensFiltradosProvider =
    Provider.family<List<Item>, TipoItem?>((ref, tipoFiltro) {
  // Assista ao valor do FutureProvider. Retorna uma lista vazia se ainda não houver dados.
  final itensAsyncValue = ref.watch(itensProximosProvider);
  final itens = itensAsyncValue.value ?? [];

  if (tipoFiltro == null) {
    return itens;
  }

  return itens.where((item) {
    if (tipoFiltro == TipoItem.aluguel) {
      return item.tipo == TipoItem.aluguel || item.tipo == TipoItem.ambos;
    }
    if (tipoFiltro == TipoItem.venda) {
      return item.tipo == TipoItem.venda || item.tipo == TipoItem.ambos;
    }
    return false;
  }).toList();
});
