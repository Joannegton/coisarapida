import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/itens/presentation/providers/item_provider.dart';
import 'package:coisarapida/core/providers/location_provider.dart';

/// Stream de todos os itens do Firestore com cálculo de distância
final todosItensStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final itensRepository = ref.watch(itemRepositoryProvider);
  final locationAsync = ref.watch(localizacaoUsuarioProvider);
  final locationService = ref.watch(locationServiceProvider);

  try {
    await for (final itens in itensRepository.getTodosItensStream()) {
      if (itens.isEmpty) {
        yield [];
        continue;
      }

      // Calcula distância se localização estiver disponível
      if (locationAsync.hasValue && locationAsync.value != null) {
        final userPosition = locationAsync.value!;
        final itensComDistancia = itens.map((item) {
          final distancia = locationService.calcularDistancia(
            userPosition.latitude,
            userPosition.longitude,
            item.localizacao.latitude!,
            item.localizacao.longitude!,
          );
          return {
            'item': item,
            'distancia': distancia,
          };
        }).toList();

        // Ordena por distância ascendente
        itensComDistancia.sort((a, b) {
          final distA = a['distancia'] as double?;
          final distB = b['distancia'] as double?;

          // Itens sem distância vão para o final
          if (distA == null && distB == null) return 0;
          if (distA == null) return 1;
          if (distB == null) return -1;

          return distA.compareTo(distB);
        });

        yield itensComDistancia;
      } else {
        final itensSemDistancia = itens.map((item) => {
          'item': item,
          'distancia': null,
        }).toList();

        yield itensSemDistancia;
      }
    }
  } catch (e) {
    rethrow;
  }
});

/// Provider que calcula distância para cada item baseado na localização do usuário
final itensComDistanciaProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final todosItensAsync = ref.watch(todosItensStreamProvider);

  if (!todosItensAsync.hasValue || todosItensAsync.value == null) {
    return [];
  }

  return todosItensAsync.value!;
});

/// Provider que retorna todos os itens ordenados por distância (ascendente)
final todosItensProximosProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final todosItensAsync = ref.watch(todosItensStreamProvider);

  if (!todosItensAsync.hasValue || todosItensAsync.value == null) {
    return [];
  }

  return todosItensAsync.value!;
});

/// Provider que filtra itens por tipo (aluguel, venda, ambos)
final itensPeloTipoItemProvider = Provider.family<List<Map<String, dynamic>>, TipoItem?>((ref, tipoItem) {
  final todosItensProximos = ref.watch(todosItensProximosProvider);
  
  if (todosItensProximos.isEmpty || tipoItem == null) {
    return todosItensProximos;
  }

  return todosItensProximos.where((itemMap) {
    final item = itemMap['item'] as Item;
    
    if (tipoItem == TipoItem.aluguel) {
      return item.tipo == TipoItem.aluguel || item.tipo == TipoItem.ambos;
    }
    if (tipoItem == TipoItem.venda) {
      return item.tipo == TipoItem.venda || item.tipo == TipoItem.ambos;
    }
    return false;
  }).toList();
});

/// Provider que filtra itens pelo termo de busca
final itensPeloTermoProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, termo) {
  final todosItensProximos = ref.watch(todosItensProximosProvider);
  
  if (todosItensProximos.isEmpty || termo.trim().isEmpty) {
    return todosItensProximos;
  }

  final termoLower = termo.toLowerCase().trim();

  return todosItensProximos.where((itemMap) {
    final item = itemMap['item'] as Item;
    return item.nome.toLowerCase().contains(termoLower) ||
           item.descricao.toLowerCase().contains(termoLower) ||
           item.categoria.toLowerCase().contains(termoLower);
  }).toList();
});