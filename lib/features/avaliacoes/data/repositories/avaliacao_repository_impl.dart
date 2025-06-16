import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
import '../../domain/entities/avaliacao.dart';
import '../../domain/repositories/avaliacao_repository.dart';
import '../models/avaliacao_model.dart';

class AvaliacaoRepositoryImpl implements AvaliacaoRepository {
  final FirebaseFirestore _firestore;

  AvaliacaoRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> criarAvaliacao(Avaliacao avaliacao) async {
    try {
      final avaliacaoModel = AvaliacaoModel.fromEntity(avaliacao);
      await _firestore
          .collection('avaliacoes')
          .doc(avaliacaoModel.id) // Usar o ID da entidade se já definido, ou deixar o Firestore gerar
          .set(avaliacaoModel.toMap());
      // TODO: Atualizar a reputação média do usuário/item avaliado.
      // Isso pode ser feito aqui ou via Cloud Function.
    } catch (e) {
      print("Erro ao criar avaliação no repositório: $e");
      throw ServerException('Erro ao registrar avaliação: ${e.toString()}');
    }
  }

  @override
  Future<List<Avaliacao>> getAvaliacoesPorUsuario(String usuarioId, {int limite = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('avaliacoes')
          .where('avaliadoId', isEqualTo: usuarioId)
          .where('tipoAvaliado', isEqualTo: TipoAvaliado.usuario.name)
          .orderBy('data', descending: true)
          .limit(limite)
          .get();
      return querySnapshot.docs.map((doc) => AvaliacaoModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException('Erro ao buscar avaliações do usuário: ${e.toString()}');
    }
  }

  @override
  Future<List<Avaliacao>> getAvaliacoesPorItem(String itemId, {int limite = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('avaliacoes')
          .where('itemId', isEqualTo: itemId) // Ou 'avaliadoId' se tipoAvaliado for 'item'
          .orderBy('data', descending: true)
          .limit(limite)
          .get();
      return querySnapshot.docs.map((doc) => AvaliacaoModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException('Erro ao buscar avaliações do item: ${e.toString()}');
    }
  }
}