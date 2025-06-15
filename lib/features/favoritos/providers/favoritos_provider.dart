import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para gerenciar itens favoritos
final favoritosProvider = StateNotifierProvider<FavoritosNotifier, List<String>>((ref) {
  return FavoritosNotifier();
});

/// Provider para lista de itens favoritos com detalhes
final itensFavoritosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final favoritos = ref.watch(favoritosProvider);
  
  // Simular delay de carregamento
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Dados mockados dos itens favoritos
  final todosItens = [
    {
      'id': '1',
      'nome': 'Furadeira Bosch',
      'categoria': 'ferramentas',
      'precoPorDia': 15.0,
      'distancia': 0.8,
      'avaliacao': 4.8,
      'fotos': ['https://via.placeholder.com/300x200?text=Furadeira'],
      'disponivel': true,
      'proprietarioNome': 'João Silva',
    },
    {
      'id': '2',
      'nome': 'Bicicleta Mountain Bike',
      'categoria': 'transporte',
      'precoPorDia': 25.0,
      'distancia': 1.2,
      'avaliacao': 4.5,
      'fotos': ['https://via.placeholder.com/300x200?text=Bike'],
      'disponivel': true,
      'proprietarioNome': 'Maria Santos',
    },
    {
      'id': '3',
      'nome': 'Mesa de Som',
      'categoria': 'eventos',
      'precoPorDia': 80.0,
      'distancia': 3.0,
      'avaliacao': 4.7,
      'fotos': ['https://via.placeholder.com/300x200?text=Mesa+Som'],
      'disponivel': false,
      'proprietarioNome': 'Pedro Oliveira',
    },
  ];
  
  // Retornar apenas itens que estão nos favoritos
  return todosItens.where((item) => favoritos.contains(item['id'])).toList();
});

class FavoritosNotifier extends StateNotifier<List<String>> {
  FavoritosNotifier() : super(['1', '2', '3']); // Alguns favoritos iniciais

  void adicionarFavorito(String itemId) {
    if (!state.contains(itemId)) {
      state = [...state, itemId];
    }
  }

  void removerFavorito(String itemId) {
    state = state.where((id) => id != itemId).toList();
  }

  bool isFavorito(String itemId) {
    return state.contains(itemId);
  }

  void toggleFavorito(String itemId) {
    if (isFavorito(itemId)) {
      removerFavorito(itemId);
    } else {
      adicionarFavorito(itemId);
    }
  }
}
