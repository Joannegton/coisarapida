import '../repositories/favorito_repository.dart';

class GetFavoritosIdsStreamUseCase {
  final FavoritoRepository repository;

  GetFavoritosIdsStreamUseCase(this.repository);

  Stream<List<String>> call(String userId) {
    return repository.getFavoritosIdsStream(userId);
  }
}
