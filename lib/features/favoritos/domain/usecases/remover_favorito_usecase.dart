import '../repositories/favorito_repository.dart';

class RemoverFavoritoUseCase {
  final FavoritoRepository repository;

  RemoverFavoritoUseCase(this.repository);

  Future<void> call({required String userId, required String itemId}) {
    return repository.removerFavorito(userId, itemId);
  }
}
