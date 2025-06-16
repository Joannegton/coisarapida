import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/avaliacao.dart';

class AvaliacaoModel extends Avaliacao {
  AvaliacaoModel({
    required super.id,
    required super.avaliadorId,
    required super.avaliadorNome,
    super.avaliadorFotoUrl,
    required super.avaliadoId,
    required super.tipoAvaliado,
    super.aluguelId,
    super.itemId,
    required super.nota,
    super.comentario,
    required super.data,
  });

  factory AvaliacaoModel.fromEntity(Avaliacao entity) {
    return AvaliacaoModel(
      id: entity.id,
      avaliadorId: entity.avaliadorId,
      avaliadorNome: entity.avaliadorNome,
      avaliadorFotoUrl: entity.avaliadorFotoUrl,
      avaliadoId: entity.avaliadoId,
      tipoAvaliado: entity.tipoAvaliado,
      aluguelId: entity.aluguelId,
      itemId: entity.itemId,
      nota: entity.nota,
      comentario: entity.comentario,
      data: entity.data,
    );
  }

  factory AvaliacaoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AvaliacaoModel(
      id: doc.id,
      avaliadorId: data['avaliadorId'] ?? '',
      avaliadorNome: data['avaliadorNome'] ?? '',
      avaliadorFotoUrl: data['avaliadorFotoUrl'],
      avaliadoId: data['avaliadoId'] ?? '',
      tipoAvaliado: TipoAvaliado.values.firstWhere(
        (e) => e.name == data['tipoAvaliado'],
        orElse: () => TipoAvaliado.usuario,
      ),
      aluguelId: data['aluguelId'],
      itemId: data['itemId'],
      nota: data['nota'] ?? 0,
      comentario: data['comentario'],
      data: (data['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id' não é salvo no mapa, pois é o ID do documento
      'avaliadorId': avaliadorId,
      'avaliadorNome': avaliadorNome,
      'avaliadorFotoUrl': avaliadorFotoUrl,
      'avaliadoId': avaliadoId,
      'tipoAvaliado': tipoAvaliado.name,
      'aluguelId': aluguelId,
      'itemId': itemId,
      'nota': nota,
      'comentario': comentario,
      'data': FieldValue.serverTimestamp(), // Alterado para usar o timestamp do servidor
    };
  }
}