import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/problema.dart';

/// Model que estende a entidade Problema
/// Responsável pela conversão entre Firestore e a entidade
class ProblemaModel extends Problema {
  ProblemaModel({
    required super.id,
    required super.aluguelId,
    required super.itemId,
    required super.reportadoPorId,
    required super.reportadoPorNome,
    required super.reportadoContraId,
    required super.tipo,
    required super.prioridade,
    required super.descricao,
    required super.fotos,
    required super.status,
    required super.criadoEm,
    super.resolvidoEm,
    super.resolucao,
  });

  /// Cria um ProblemaModel a partir de uma entidade Problema
  factory ProblemaModel.fromEntity(Problema entity) {
    return ProblemaModel(
      id: entity.id,
      aluguelId: entity.aluguelId,
      itemId: entity.itemId,
      reportadoPorId: entity.reportadoPorId,
      reportadoPorNome: entity.reportadoPorNome,
      reportadoContraId: entity.reportadoContraId,
      tipo: entity.tipo,
      prioridade: entity.prioridade,
      descricao: entity.descricao,
      fotos: entity.fotos,
      status: entity.status,
      criadoEm: entity.criadoEm,
      resolvidoEm: entity.resolvidoEm,
      resolucao: entity.resolucao,
    );
  }

  /// Cria um ProblemaModel a partir de um documento Firestore
  factory ProblemaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento ${doc.id} não encontrado ou dados nulos.');
    }

    return ProblemaModel(
      id: doc.id,
      aluguelId: data['aluguelId'] as String? ?? '',
      itemId: data['itemId'] as String? ?? '',
      reportadoPorId: data['reportadoPorId'] as String? ?? '',
      reportadoPorNome: data['reportadoPorNome'] as String? ?? '',
      reportadoContraId: data['reportadoContraId'] as String? ?? '',
      tipo: _tipoFromString(data['tipo'] as String?),
      prioridade: _prioridadeFromString(data['prioridade'] as String?),
      descricao: data['descricao'] as String? ?? '',
      fotos: List<String>.from(data['fotos'] as List? ?? []),
      status: _statusFromString(data['status'] as String?),
      criadoEm: (data['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvidoEm: (data['resolvidoEm'] as Timestamp?)?.toDate(),
      resolucao: data['resolucao'] as String?,
    );
  }

  /// Converte string para TipoProblema
  static TipoProblema _tipoFromString(String? tipo) {
    return TipoProblema.values.firstWhere(
      (e) => e.name == tipo,
      orElse: () => TipoProblema.outro,
    );
  }

  /// Converte string para PrioridadeProblema
  static PrioridadeProblema _prioridadeFromString(String? prioridade) {
    return PrioridadeProblema.values.firstWhere(
      (e) => e.name == prioridade,
      orElse: () => PrioridadeProblema.media,
    );
  }

  /// Converte string para StatusProblema
  static StatusProblema _statusFromString(String? status) {
    return StatusProblema.values.firstWhere(
      (e) => e.name == status,
      orElse: () => StatusProblema.aberto,
    );
  }

  /// Converte o model para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'aluguelId': aluguelId,
      'itemId': itemId,
      'reportadoPorId': reportadoPorId,
      'reportadoPorNome': reportadoPorNome,
      'reportadoContraId': reportadoContraId,
      'tipo': tipo.name,
      'prioridade': prioridade.name,
      'descricao': descricao,
      'fotos': fotos,
      'status': status.name,
      'criadoEm': FieldValue.serverTimestamp(),
      'resolvidoEm': resolvidoEm != null ? Timestamp.fromDate(resolvidoEm!) : null,
      'resolucao': resolucao,
    };
  }

  /// Converte o model para Map para atualização no Firestore
  Map<String, dynamic> toMapForUpdate() {
    return {
      'status': status.name,
      'resolvidoEm': resolvidoEm != null ? Timestamp.fromDate(resolvidoEm!) : null,
      'resolucao': resolucao,
    };
  }
}
