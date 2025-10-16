import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/denuncia.dart';

/// Model que estende a entidade Denuncia
/// Responsável pela conversão entre Firestore e a entidade
class DenunciaModel extends Denuncia {
  const DenunciaModel({
    required super.id,
    required super.aluguelId,
    required super.denuncianteId,
    required super.denunciadoId,
    required super.tipo,
    required super.descricao,
    required super.evidencias,
    required super.status,
    required super.criadaEm,
    super.resolvidaEm,
    super.resolucao,
    super.moderadorId,
  });

  /// Cria um DenunciaModel a partir de uma entidade Denuncia
  factory DenunciaModel.fromEntity(Denuncia entity) {
    return DenunciaModel(
      id: entity.id,
      aluguelId: entity.aluguelId,
      denuncianteId: entity.denuncianteId,
      denunciadoId: entity.denunciadoId,
      tipo: entity.tipo,
      descricao: entity.descricao,
      evidencias: entity.evidencias,
      status: entity.status,
      criadaEm: entity.criadaEm,
      resolvidaEm: entity.resolvidaEm,
      resolucao: entity.resolucao,
      moderadorId: entity.moderadorId,
    );
  }

  /// Cria um DenunciaModel a partir de um documento Firestore
  factory DenunciaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento ${doc.id} não encontrado ou dados nulos.');
    }

    return DenunciaModel(
      id: doc.id,
      aluguelId: data['aluguelId'] as String? ?? '',
      denuncianteId: data['denuncianteId'] as String? ?? '',
      denunciadoId: data['denunciadoId'] as String? ?? '',
      tipo: _tipoFromString(data['tipo'] as String?),
      descricao: data['descricao'] as String? ?? '',
      evidencias: List<String>.from(data['evidencias'] as List? ?? []),
      status: _statusFromString(data['status'] as String?),
      criadaEm: (data['criadaEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvidaEm: (data['resolvidaEm'] as Timestamp?)?.toDate(),
      resolucao: data['resolucao'] as String?,
      moderadorId: data['moderadorId'] as String?,
    );
  }

  /// Converte string para TipoDenuncia
  static TipoDenuncia _tipoFromString(String? tipo) {
    return TipoDenuncia.values.firstWhere(
      (e) => e.name == tipo,
      orElse: () => TipoDenuncia.outros,
    );
  }

  /// Converte string para StatusDenuncia
  static StatusDenuncia _statusFromString(String? status) {
    return StatusDenuncia.values.firstWhere(
      (e) => e.name == status,
      orElse: () => StatusDenuncia.pendente,
    );
  }

  /// Converte o model para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'aluguelId': aluguelId,
      'denuncianteId': denuncianteId,
      'denunciadoId': denunciadoId,
      'tipo': tipo.name,
      'descricao': descricao,
      'evidencias': evidencias,
      'status': status.name,
      'criadaEm': FieldValue.serverTimestamp(),
      'resolvidaEm': resolvidaEm != null ? Timestamp.fromDate(resolvidaEm!) : null,
      'resolucao': resolucao,
      'moderadorId': moderadorId,
    };
  }

  /// Converte o model para Map para atualização no Firestore
  Map<String, dynamic> toMapForUpdate() {
    return {
      'status': status.name,
      'resolvidaEm': resolvidaEm != null ? Timestamp.fromDate(resolvidaEm!) : null,
      'resolucao': resolucao,
      'moderadorId': moderadorId,
    };
  }
}
