import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/favoritos/domain/usecases/adicionar_favorito_usecase.dart';
import 'package:coisarapida/features/favoritos/domain/usecases/get_favoritos_ids_stream_usecase.dart';
import 'package:coisarapida/features/favoritos/domain/usecases/remover_favorito_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart'; // Necessário para o ID do usuário
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart'; // Alterado para sua entidade Usuario
import 'favorito_core_providers.dart'; // Importar os novos providers

/// Provider para gerenciar itens favoritos
final favoritosProvider = StateNotifierProvider<FavoritosNotifier, List<String>>((ref) {
  return FavoritosNotifier(ref);
});

/// Provider para lista de itens favoritos com detalhes
final itensFavoritosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final favoritoIds = ref.watch(favoritosProvider);
  final authState = ref.watch(usuarioAtualProvider);
  final userId = authState.valueOrNull?.id;

  if (userId == null) {
    // Usuário não logado ou estado de autenticação carregando/erro
    return [];
  }

  if (favoritoIds.isEmpty) {
    return [];
  }

  // Buscar detalhes dos itens da coleção 'itens'
  // O Firestore suporta até 30 IDs na cláusula 'whereIn' com FieldPath.documentId.
  // Se a lista de favoritos puder ser maior, considere buscar em lotes ou individualmente.
  if (favoritoIds.length > 30) {
    // Exemplo de busca individual (menos eficiente para muitos itens, mas funciona sem limite de 'whereIn')
    List<Map<String, dynamic>> itemsDetails = [];
    for (final itemId in favoritoIds) {
      final docSnap = await firestore.collection('itens').doc(itemId).get();
      if (docSnap.exists) {
        final data = docSnap.data()!;
        data['id'] = docSnap.id; // Garante que o 'id' do item esteja no mapa
        itemsDetails.add(data);
      }
    }
    return itemsDetails;
  } else {
    // Usar 'whereIn' para listas menores/médias
    final querySnapshot = await firestore
        .collection('itens')
        .where(FieldPath.documentId, whereIn: favoritoIds)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Garante que o 'id' do item esteja no mapa
      // Certifique-se de que todos os campos esperados pela FavoritosPage._buildItemCard estão presentes
      // Ex: 'nome', 'categoria', 'precoPorDia', 'distancia', 'avaliacao', 'fotos', 'disponivel', 'proprietarioNome'
      // Trate nulos ou campos ausentes de forma adequada se o esquema não for estrito.
      return data;
    }).toList();
  }
});

class FavoritosNotifier extends StateNotifier<List<String>> {
  final Ref _ref;
  String? _userId;
  ProviderSubscription? _authSubscription; // Alterado aqui
  StreamSubscription? _favoritesSubscription;

  // UseCases
  late final GetFavoritosIdsStreamUseCase _getFavoritosIdsStreamUseCase;
  late final AdicionarFavoritoUseCase _adicionarFavoritoUseCase;
  late final RemoverFavoritoUseCase _removerFavoritoUseCase;

  FavoritosNotifier(this._ref)
      : super([]) {
    _getFavoritosIdsStreamUseCase = _ref.read(getFavoritosIdsStreamUseCaseProvider);
    _adicionarFavoritoUseCase = _ref.read(adicionarFavoritoUseCaseProvider);
    _removerFavoritoUseCase = _ref.read(removerFavoritoUseCaseProvider);

    _authSubscription = _ref.listen<AsyncValue<Usuario?>>( // Alterado para Usuario?
      usuarioAtualProvider,
      (_, next) {
        final user = next.valueOrNull;
        _updateUserAndSubscribeToFavorites(user?.id);
      },
      fireImmediately: true,
    );
  }

  void _updateUserAndSubscribeToFavorites(String? newUserId) {
    if (_userId == newUserId && newUserId != null) return;

    _favoritesSubscription?.cancel();
    _userId = newUserId;

    if (_userId != null) {
      _favoritesSubscription = _getFavoritosIdsStreamUseCase
          .call(_userId!)
          .listen(
        (ids) { // 'snapshot' aqui já é a List<String>
          // final ids = snapshot.docs.map((doc) => doc.id).toList(); // Linha removida/alterada
          if (mounted) state = ids;
        },
        onError: (error) {
          print("Erro ao carregar favoritos do Firestore: $error");
          if (mounted) state = [];
        },
      );
    } else {
      if (mounted) state = [];
    }
  }

  Future<void> adicionarFavorito(String itemId) async {
    if (_userId == null) throw Exception('Usuário não logado para adicionar favorito.');
    if (state.contains(itemId)) return; // Já é favorito

    state = [...state, itemId]; // Atualização otimista
    try {
      await _adicionarFavoritoUseCase.call(userId: _userId!, itemId: itemId);
    } catch (e) { //melhorar os erros futuramente pq não tem erro direito
      state = state.where((id) => id != itemId).toList(); // Reverte em caso de erro
      print("Erro ao adicionar favorito no Firestore: $e");
      rethrow;
    }
  }

  Future<void> removerFavorito(String itemId) async {
    if (_userId == null) throw Exception('Usuário não logado para remover favorito.');
    if (!state.contains(itemId)) return; // Não é favorito

    final originalState = List<String>.from(state);
    state = state.where((id) => id != itemId).toList(); // Atualização otimista
    try {
      await _removerFavoritoUseCase.call(userId: _userId!, itemId: itemId);
    } catch (e) {
      state = originalState; // Reverte em caso de erro
      print("Erro ao remover favorito no Firestore: $e");
      rethrow;
    }
  }

  bool isFavorito(String itemId) {
    return state.contains(itemId);
  }

  Future<void> toggleFavorito(String itemId) async {
    if (isFavorito(itemId)) {
      await removerFavorito(itemId);
    } else {
      await adicionarFavorito(itemId);
    }
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}
