abstract class FavoritoRepository {
  Stream<List<String>> getFavoritosIdsStream(String userId);
  Future<void> adicionarFavorito(String userId, String itemId);
  Future<void> removerFavorito(String userId, String itemId);
}
