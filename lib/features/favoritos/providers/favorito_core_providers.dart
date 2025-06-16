import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/favorito_repository_impl.dart';
import '../domain/repositories/favorito_repository.dart';
import '../domain/usecases/adicionar_favorito_usecase.dart';
import '../domain/usecases/get_favoritos_ids_stream_usecase.dart';
import '../domain/usecases/remover_favorito_usecase.dart';

// Provider para o Repositório
final favoritoRepositoryProvider = Provider<FavoritoRepository>((ref) {
  return FavoritoRepositoryImpl(firestore: FirebaseFirestore.instance);
});

// Providers para os UseCases
final getFavoritosIdsStreamUseCaseProvider = Provider<GetFavoritosIdsStreamUseCase>((ref) {
  final repository = ref.watch(favoritoRepositoryProvider);
  return GetFavoritosIdsStreamUseCase(repository);
});

final adicionarFavoritoUseCaseProvider = Provider<AdicionarFavoritoUseCase>((ref) {
  final repository = ref.watch(favoritoRepositoryProvider);
  return AdicionarFavoritoUseCase(repository);
});

final removerFavoritoUseCaseProvider = Provider<RemoverFavoritoUseCase>((ref) {
  final repository = ref.watch(favoritoRepositoryProvider);
  return RemoverFavoritoUseCase(repository);
});
