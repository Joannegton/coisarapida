import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
import 'package:coisarapida/features/alugueis/domain/entities/caucao_aluguel.dart';
import '../../domain/entities/aluguel.dart';
import '../../domain/repositories/aluguel_repository.dart';
import '../models/aluguel_model.dart';

class AluguelRepositoryImpl implements AluguelRepository {
  final FirebaseFirestore _firestore;

  AluguelRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> solicitarAluguel(Aluguel aluguel) async {
    try {
      final aluguelModel = AluguelModel.fromEntity(aluguel);
      final docRef = _firestore
          .collection('alugueis')
          .doc(aluguelModel.id.isNotEmpty ? aluguelModel.id : null);
      await docRef.set(aluguelModel.toMap());
      return docRef.id;
    } catch (e) {
      throw ServerException('Erro ao solicitar aluguel: ${e.toString()}');
    }
  }

  @override
  Future<void> atualizarStatusAluguel(
      String aluguelId, StatusAluguel novoStatus,
      {String? motivo}) async {
    try {
      Map<String, dynamic> dataToUpdate = {
        'status': novoStatus.name,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };
      if (novoStatus == StatusAluguel.recusado && motivo != null) {
        dataToUpdate['motivoRecusaLocador'] = motivo;
      }

      // Atualizar status do aluguel
      await _firestore
          .collection('alugueis')
          .doc(aluguelId)
          .update(dataToUpdate);

      // Se o aluguel foi aprovado, marcar o item como indisponível
      if (novoStatus == StatusAluguel.aprovado) {
        // Buscar o aluguel para obter o itemId
        final aluguelDoc =
            await _firestore.collection('alugueis').doc(aluguelId).get();

        if (aluguelDoc.exists) {
          final aluguelData = aluguelDoc.data();
          final itemId = aluguelData?['itemId'] as String?;

          if (itemId != null) {
            // Atualizar o status de disponibilidade do item
            await _firestore.collection('itens').doc(itemId).update({
              'disponivel': false,
              'atualizadoEm': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Se o aluguel foi concluído ou cancelado, marcar o item como disponível novamente
      if (novoStatus == StatusAluguel.concluido ||
          novoStatus == StatusAluguel.cancelado) {
        // Buscar o aluguel para obter o itemId
        final aluguelDoc =
            await _firestore.collection('alugueis').doc(aluguelId).get();

        if (aluguelDoc.exists) {
          final aluguelData = aluguelDoc.data();
          final itemId = aluguelData?['itemId'] as String?;

          if (itemId != null) {
            // Atualizar o status de disponibilidade do item
            await _firestore.collection('itens').doc(itemId).update({
              'disponivel': true,
              'atualizadoEm': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      throw ServerException(
          'Erro ao atualizar status do aluguel: ${e.toString()}');
    }
  }

  @override
  Future<Aluguel?> getAluguelPorId(String aluguelId) async {
    try {
      final doc = await _firestore.collection('alugueis').doc(aluguelId).get();
      if (doc.exists) {
        return AluguelModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw ServerException('Erro ao buscar aluguel: ${e.toString()}');
    }
  }

  @override
  @override
  Stream<Aluguel?> getAluguelStream(String aluguelId) {
    try {
      return _firestore
          .collection('alugueis')
          .doc(aluguelId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return AluguelModel.fromFirestore(doc);
        }
        return null;
      });
    } catch (e) {
      throw ServerException(
          'Erro ao buscar stream do aluguel: ${e.toString()}');
    }
  }

  @override
  Stream<List<Aluguel>> getAlugueisPorUsuario(String usuarioId,
      {bool comoLocador = false, bool comoLocatario = false}) {
    Query query = _firestore.collection('alugueis');

    if (comoLocador) {
      query = query.where('locadorId', isEqualTo: usuarioId);
    } else if (comoLocatario) {
      query = query.where('locatarioId', isEqualTo: usuarioId);
    } else {
      return Stream.value([]);
    }

    return query
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AluguelModel.fromFirestore(
              doc as QueryDocumentSnapshot<Map<String, dynamic>>))
          .toList();
    }).handleError((error) {
      throw ServerException(
          'Erro ao buscar aluguéis do usuário: ${error.toString()}');
    });
  }

  @override
  Future<void> processarPagamentoCaucaoAluguel({
    required String aluguelId,
    required String metodoPagamento,
    required String transacaoId,
  }) async {
    try {
      await _firestore.collection('alugueis').doc(aluguelId).update({
        'caucao.status': StatusCaucaoAluguel.bloqueada.name,
        'caucao.metodoPagamento': metodoPagamento,
        'caucao.transacaoId': transacaoId,
        'caucao.dataBloqueio': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(
          'Erro ao processar pagamento da caução do aluguel: ${e.toString()}');
    }
  }

  @override
  Future<void> liberarCaucaoAluguel({
    required String aluguelId,
    String? motivoRetencao,
    double? valorRetido,
  }) async {
    try {
      await _firestore.collection('alugueis').doc(aluguelId).update({
        'caucao.status': valorRetido != null && valorRetido > 0
            ? StatusCaucaoAluguel.utilizadaParcialmente.name
            : StatusCaucaoAluguel.liberada.name,
        'caucao.dataLiberacao': FieldValue.serverTimestamp(),
        'caucao.motivoRetencao': motivoRetencao,
        'caucao.valorRetido': valorRetido,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(
          'Erro ao liberar caução do aluguel: ${e.toString()}');
    }
  }

  @override
  Future<void> incrementarTotalAlugueisItem(String itemId) async {
    try {
      await _firestore.collection('itens').doc(itemId).update({
        'totalAlugueis': FieldValue.increment(1),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(
          'Erro ao incrementar total de aluguéis do item: ${e.toString()}');
    }
  }
}
