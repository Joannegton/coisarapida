import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
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
      final docRef = _firestore.collection('alugueis').doc(aluguelModel.id.isNotEmpty ? aluguelModel.id : null);
      await docRef.set(aluguelModel.toMap());
      return docRef.id;
    } catch (e) {
      throw ServerException('Erro ao solicitar aluguel: ${e.toString()}');
    }
  }

  @override
  Future<void> atualizarStatusAluguel(String aluguelId, StatusAluguel novoStatus, {String? motivo}) async {
    try {
      Map<String, dynamic> dataToUpdate = {
        'status': novoStatus.name,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };
      if (novoStatus == StatusAluguel.recusado && motivo != null) {
        dataToUpdate['motivoRecusaLocador'] = motivo;
      }
      // adc outras logicas de campos baseadas no status, se necessário
      await _firestore.collection('alugueis').doc(aluguelId).update(dataToUpdate);
    } catch (e) {
      throw ServerException('Erro ao atualizar status do aluguel: ${e.toString()}');
    }
  }

  @override
  Future<Aluguel?> getAluguelPorId(String aluguelId) async {
    try {
      final doc = await _firestore.collection('alugueis').doc(aluguelId).get();
      if (doc.exists) {
        return AluguelModel.fromFirestore(doc as QueryDocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    } catch (e) {
      throw ServerException('Erro ao buscar aluguel: ${e.toString()}');
    }
  }

  @override
  Stream<List<Aluguel>> getAlugueisPorUsuario(String usuarioId, {bool comoLocador = false, bool comoLocatario = false}) {
    Query query = _firestore.collection('alugueis');

    if (comoLocador && comoLocatario) {
      query = query.where('participantes', arrayContains: usuarioId);
    } else if (comoLocador) {
      query = query.where('locadorId', isEqualTo: usuarioId);
    } else if (comoLocatario) {
      query = query.where('locatarioId', isEqualTo: usuarioId);
    } else {
      // TODO Se nenhum for especificado, pode retornar vazio ou lançar erro,
      // ou buscar por 'participantes' como padrão.
      query = query.where('participantes', arrayContains: usuarioId);
    }

    return query.orderBy('criadoEm', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AluguelModel.fromFirestore(doc as QueryDocumentSnapshot<Map<String, dynamic>>))
          .toList();
    }).handleError((error) {
      throw ServerException('Erro ao buscar aluguéis do usuário: ${error.toString()}');
    });
  }

  @override
  Stream<List<Aluguel>> getSolicitacoesPendentesParaLocador(String locadorId) {
    return _firestore
        .collection('alugueis')
        .where('locadorId', isEqualTo: locadorId)
        .where('status', isEqualTo: StatusAluguel.solicitado.name)
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            final alugueis = snapshot.docs
              .map((doc) {
                return AluguelModel.fromFirestore(doc);
              })
              .toList();
            return alugueis;
          } catch (e) {
            throw ServerException('Erro ao mapear solicitações pendentes: ${e.toString()}'); // Re-throw para ser pego pelo handleError
          }
        })
        .handleError((error) {
      // O StreamProvider deve converter isso para um AsyncError
      throw ServerException('Erro no stream de solicitações pendentes: ${error.toString()}');
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
        'caucao.status': StatusAluguelCaucao.bloqueada.name,
        'caucao.metodoPagamento': metodoPagamento,
        'caucao.transacaoId': transacaoId,
        'caucao.dataBloqueio': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Erro ao processar pagamento da caução do aluguel: ${e.toString()}');
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
        'caucao.status': valorRetido != null && valorRetido > 0 ? StatusAluguelCaucao.utilizadaParcialmente.name : StatusAluguelCaucao.liberada.name,
        'caucao.dataLiberacao': FieldValue.serverTimestamp(),
        'caucao.motivoRetencao': motivoRetencao,
        'caucao.valorRetido': valorRetido,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Erro ao liberar caução do aluguel: ${e.toString()}');
    }
  }
}