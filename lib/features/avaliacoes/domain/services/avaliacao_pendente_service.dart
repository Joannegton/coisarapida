import 'package:cloud_firestore/cloud_firestore.dart';

class AvaliacaoPendenteService {
  final FirebaseFirestore _firestore;

  AvaliacaoPendenteService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Cria uma avaliação pendente após finalizar um aluguel
  Future<void> criarAvaliacaoPendente({
    required String aluguelId,
    required String itemId,
    String? itemNome,
    required String avaliadorId,
    required String avaliadoId,
    String? avaliadoNome,
    String? avaliadoFoto,
    required String tipoUsuario, // 'locador' ou 'locatario'
  }) async {
    final docId = '${aluguelId}_${avaliadorId}_${tipoUsuario}';

    await _firestore.collection('avaliacoes_pendentes').doc(docId).set({
      'id': docId,
      'aluguelId': aluguelId,
      'itemId': itemId,
      'itemNome': itemNome,
      'avaliadorId': avaliadorId,
      'avaliadoId': avaliadoId,
      'avaliadoNome': avaliadoNome ?? 'Usuário',
      'avaliadoFoto': avaliadoFoto,
      'tipoUsuario': tipoUsuario,
      'usuarioId': avaliadorId, // Para facilitar queries
      'status': 'pendente',
      'dataCriacao': FieldValue.serverTimestamp(),
      'dataFinalizacao': null,
    });
  }

  /// Marca uma avaliação pendente como concluída
  Future<void> marcarAvaliacaoConcluida(String avaliacaoPendenteId) async {
    await _firestore.collection('avaliacoes_pendentes').doc(avaliacaoPendenteId).update({
      'status': 'concluida',
      'dataFinalizacao': FieldValue.serverTimestamp(),
    });
  }

  /// Obtém avaliações pendentes do usuário atual
  Stream<List<Map<String, dynamic>>> getAvaliacoesPendentes(String usuarioId) {
    return _firestore
        .collection('avaliacoes_pendentes')
        .where('usuarioId', isEqualTo: usuarioId)
        .where('status', isEqualTo: 'pendente')
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Verifica se há avaliações pendentes para o usuário
  Future<bool> temAvaliacoesPendentes(String usuarioId) async {
    final snapshot = await _firestore
        .collection('avaliacoes_pendentes')
        .where('usuarioId', isEqualTo: usuarioId)
        .where('status', isEqualTo: 'pendente')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Obtém a primeira avaliação pendente (para redirecionamento)
  Future<Map<String, dynamic>?> getPrimeiraAvaliacaoPendente(String usuarioId) async {
    final snapshot = await _firestore
        .collection('avaliacoes_pendentes')
        .where('usuarioId', isEqualTo: usuarioId)
        .where('status', isEqualTo: 'pendente')
        .orderBy('dataCriacao')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }
}
