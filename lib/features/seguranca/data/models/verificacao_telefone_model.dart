import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/verificacao_telefone.dart';

/// Model que estende a entidade VerificacaoTelefone
class VerificacaoTelefoneModel extends VerificacaoTelefone {
  const VerificacaoTelefoneModel({
    required super.id,
    required super.usuarioId,
    required super.telefone,
    super.codigoVerificacao,
    required super.status,
    required super.dataCriacao,
    super.dataUltimaTentativa,
    required super.tentativas,
    super.dataExpiracao,
    required super.verificado,
  });

  /// Cria um VerificacaoTelefoneModel a partir de uma entidade VerificacaoTelefone
  factory VerificacaoTelefoneModel.fromEntity(VerificacaoTelefone entity) {
    return VerificacaoTelefoneModel(
      id: entity.id,
      usuarioId: entity.usuarioId,
      telefone: entity.telefone,
      codigoVerificacao: entity.codigoVerificacao,
      status: entity.status,
      dataCriacao: entity.dataCriacao,
      dataUltimaTentativa: entity.dataUltimaTentativa,
      tentativas: entity.tentativas,
      dataExpiracao: entity.dataExpiracao,
      verificado: entity.verificado,
    );
  }

  /// Cria um VerificacaoTelefoneModel a partir de um documento Firestore
  factory VerificacaoTelefoneModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return VerificacaoTelefoneModel(
      id: doc.id,
      usuarioId: data['usuarioId'] as String? ?? '',
      telefone: data['telefone'] as String? ?? '',
      codigoVerificacao: data['codigoVerificacao'] as String?,
      status: _parseStatus(data['status'] as String?),
      dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataUltimaTentativa: (data['dataUltimaTentativa'] as Timestamp?)?.toDate(),
      tentativas: data['tentativas'] as int? ?? 0,
      dataExpiracao: (data['dataExpiracao'] as Timestamp?)?.toDate(),
      verificado: data['verificado'] as bool? ?? false,
    );
  }

  /// Converte para um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'usuarioId': usuarioId,
      'telefone': telefone,
      'codigoVerificacao': codigoVerificacao,
      'status': status.name,
      'dataCriacao': Timestamp.fromDate(dataCriacao),
      'dataUltimaTentativa': dataUltimaTentativa != null ? Timestamp.fromDate(dataUltimaTentativa!) : null,
      'tentativas': tentativas,
      'dataExpiracao': dataExpiracao != null ? Timestamp.fromDate(dataExpiracao!) : null,
      'verificado': verificado,
    };
  }

  /// Converte para um mapa para enviar para Cloud Functions
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'telefone': telefone,
      'codigoVerificacao': codigoVerificacao,
      'status': status.name,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataUltimaTentativa': dataUltimaTentativa?.toIso8601String(),
      'tentativas': tentativas,
      'dataExpiracao': dataExpiracao?.toIso8601String(),
      'verificado': verificado,
    };
  }

  /// Converte um status de string para enum
  static StatusVerificacaoTelefone _parseStatus(String? statusString) {
    switch (statusString) {
      case 'codigoEnviado':
        return StatusVerificacaoTelefone.codigoEnviado;
      case 'verificado':
        return StatusVerificacaoTelefone.verificado;
      case 'expirado':
        return StatusVerificacaoTelefone.expirado;
      case 'bloqueado':
        return StatusVerificacaoTelefone.bloqueado;
      case 'falhaEnvio':
        return StatusVerificacaoTelefone.falhaEnvio;
      case 'cancelado':
        return StatusVerificacaoTelefone.cancelado;
      default:
        return StatusVerificacaoTelefone.codigoEnviado;
    }
  }
}
