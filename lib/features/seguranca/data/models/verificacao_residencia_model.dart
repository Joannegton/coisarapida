import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/verificacao_residencia.dart';

/// Model que estende a entidade VerificacaoResidencia
class VerificacaoResidenciaModel extends VerificacaoResidencia {
  const VerificacaoResidenciaModel({
    required super.id,
    required super.usuarioId,
    required super.endereco,
    super.comprovanteUrl,
    required super.status,
    required super.dataCriacao,
    super.dataAtualizacao,
    super.moderadorId,
    super.observacoesModerador,
    required super.aprovado,
  });

  /// Cria um VerificacaoResidenciaModel a partir de uma entidade VerificacaoResidencia
  factory VerificacaoResidenciaModel.fromEntity(VerificacaoResidencia entity) {
    return VerificacaoResidenciaModel(
      id: entity.id,
      usuarioId: entity.usuarioId,
      endereco: entity.endereco,
      comprovanteUrl: entity.comprovanteUrl,
      status: entity.status,
      dataCriacao: entity.dataCriacao,
      dataAtualizacao: entity.dataAtualizacao,
      moderadorId: entity.moderadorId,
      observacoesModerador: entity.observacoesModerador,
      aprovado: entity.aprovado,
    );
  }

  /// Cria um VerificacaoResidenciaModel a partir de um documento Firestore
  factory VerificacaoResidenciaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return VerificacaoResidenciaModel(
      id: doc.id,
      usuarioId: data['usuarioId'] as String? ?? '',
      endereco: EnderecoVerificacao.fromMap(data['endereco'] as Map<String, dynamic>? ?? {}),
      comprovanteUrl: data['comprovanteUrl'] as String?,
      status: _parseStatus(data['status'] as String?),
      dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataAtualizacao: (data['dataAtualizacao'] as Timestamp?)?.toDate(),
      moderadorId: data['moderadorId'] as String?,
      observacoesModerador: data['observacoesModerador'] as String?,
      aprovado: data['aprovado'] as bool? ?? false,
    );
  }

  /// Converte para um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'usuarioId': usuarioId,
      'endereco': endereco.toMap(),
      'comprovanteUrl': comprovanteUrl,
      'status': status.name,
      'dataCriacao': Timestamp.fromDate(dataCriacao),
      'dataAtualizacao': dataAtualizacao != null ? Timestamp.fromDate(dataAtualizacao!) : null,
      'moderadorId': moderadorId,
      'observacoesModerador': observacoesModerador,
      'aprovado': aprovado,
    };
  }

  /// Converte para um mapa para enviar para Cloud Functions
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'endereco': endereco.toMap(),
      'comprovanteUrl': comprovanteUrl,
      'status': status.name,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao?.toIso8601String(),
      'moderadorId': moderadorId,
      'observacoesModerador': observacoesModerador,
      'aprovado': aprovado,
    };
  }

  /// Converte um status de string para enum
  static StatusVerificacaoResidencia _parseStatus(String? statusString) {
    switch (statusString) {
      case 'pendente':
        return StatusVerificacaoResidencia.pendente;
      case 'emAnalise':
        return StatusVerificacaoResidencia.emAnalise;
      case 'aprovada':
        return StatusVerificacaoResidencia.aprovada;
      case 'rejeitada':
        return StatusVerificacaoResidencia.rejeitada;
      case 'documentoSolicitado':
        return StatusVerificacaoResidencia.documentoSolicitado;
      case 'cancelada':
        return StatusVerificacaoResidencia.cancelada;
      case 'erro':
        return StatusVerificacaoResidencia.erro;
      default:
        return StatusVerificacaoResidencia.pendente;
    }
  }
}
