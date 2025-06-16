import '../repositories/favorito_repository.dart';

class AdicionarFavoritoUseCase {
  final FavoritoRepository repository;

  AdicionarFavoritoUseCase(this.repository);

  Future<void> call({required String userId, required String itemId}) {
    return repository.adicionarFavorito(userId, itemId);
  }
}
