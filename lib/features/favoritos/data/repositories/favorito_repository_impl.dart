import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/favorito_repository.dart';

class FavoritoRepositoryImpl implements FavoritoRepository {
  final FirebaseFirestore _firestore;

  FavoritoRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<String>> getFavoritosIdsStream(String userId) {
    return _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('favoritos')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    }).handleError((error) {
      // Adicionar tratamento de erro mais robusto se necessário
      print("Erro ao buscar stream de favoritos: $error");
      return <String>[]; // Retorna lista vazia em caso de erro no stream
    });
  }

  @override
  Future<void> adicionarFavorito(String userId, String itemId) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('favoritos')
          .doc(itemId)
          .set({'favoritedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      // Lançar uma exceção específica ou tratar o erro
      print("Erro ao adicionar favorito no repositório: $e");
      rethrow;
    }
  }

  @override
  Future<void> removerFavorito(String userId, String itemId) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('favoritos')
          .doc(itemId)
          .delete();
    } catch (e) {
      // Lançar uma exceção específica ou tratar o erro
      print("Erro ao remover favorito no repositório: $e");
      rethrow;
    }
  }
}
