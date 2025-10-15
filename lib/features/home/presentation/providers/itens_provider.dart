import 'package:coisarapida/features/itens/data/models/item_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/itens/presentation/providers/item_provider.dart'; // Para itemRepositoryProvider
import 'package:coisarapida/core/providers/location_provider.dart';
import 'package:geolocator/geolocator.dart';

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

/// Provider para itens com distância calculada
final itensComDistanciaProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final itensAsync = ref.watch(itensProximosProvider);
  final locationAsync = ref.watch(userLocationProvider);

  if (!itensAsync.hasValue) return [];

  final itens = itensAsync.value!;

  if (!locationAsync.hasValue) {
    // Retorna itens sem distância
    return itens.map((item) => {'item': item, 'distancia': null}).toList();
  }

  final userPosition = locationAsync.value!;
  final locationService = ref.watch(locationServiceProvider);

  return itens.map((item) {
    final distancia = locationService.calcularDistancia(
      userPosition.latitude,
      userPosition.longitude,
      item.localizacao.latitude,
      item.localizacao.longitude,
    );
    return {
      'item': item,
      'distancia': distancia,
    };
  }).toList();
});

final itensFiltradosProvider =
    Provider.family<List<Map<String, dynamic>>, TipoItem?>((ref, tipoFiltro) {
  // Assista ao valor do Provider. Retorna uma lista vazia se ainda não houver dados.
  final itensComDistancia = ref.watch(itensComDistanciaProvider);

  if (tipoFiltro == null) {
    return itensComDistancia;
  }

  return itensComDistancia.where((itemMap) {
    final item = itemMap['item'] as Item;
    if (tipoFiltro == TipoItem.aluguel) {
      return item.tipo == TipoItem.aluguel || item.tipo == TipoItem.ambos;
    }
    if (tipoFiltro == TipoItem.venda) {
      return item.tipo == TipoItem.venda || item.tipo == TipoItem.ambos;
    }
    return false;
  }).toList();
});
