/// Entidade que representa uma verificação de telefone por SMS
class VerificacaoTelefone {
  /// ID único da verificação
  final String id;

  /// ID do usuário que está sendo verificado
  final String usuarioId;

  /// Número de telefone sendo verificado
  final String telefone;

  /// Código de verificação enviado por SMS
  final String? codigoVerificacao;

  /// Status da verificação
  final StatusVerificacaoTelefone status;

  /// Data de criação da verificação
  final DateTime dataCriacao;

  /// Data da última tentativa
  final DateTime? dataUltimaTentativa;

  /// Número de tentativas realizadas
  final int tentativas;

  /// Data de expiração do código
  final DateTime? dataExpiracao;

  /// Se a verificação foi concluída com sucesso
  final bool verificado;

  const VerificacaoTelefone({
    required this.id,
    required this.usuarioId,
    required this.telefone,
    this.codigoVerificacao,
    required this.status,
    required this.dataCriacao,
    this.dataUltimaTentativa,
    required this.tentativas,
    this.dataExpiracao,
    required this.verificado,
  });

  /// Cria uma cópia da entidade com campos modificados
  VerificacaoTelefone copyWith({
    String? id,
    String? usuarioId,
    String? telefone,
    String? codigoVerificacao,
    StatusVerificacaoTelefone? status,
    DateTime? dataCriacao,
    DateTime? dataUltimaTentativa,
    int? tentativas,
    DateTime? dataExpiracao,
    bool? verificado,
  }) {
    return VerificacaoTelefone(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      telefone: telefone ?? this.telefone,
      codigoVerificacao: codigoVerificacao ?? this.codigoVerificacao,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataUltimaTentativa: dataUltimaTentativa ?? this.dataUltimaTentativa,
      tentativas: tentativas ?? this.tentativas,
      dataExpiracao: dataExpiracao ?? this.dataExpiracao,
      verificado: verificado ?? this.verificado,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VerificacaoTelefone &&
        other.id == id &&
        other.usuarioId == usuarioId &&
        other.telefone == telefone &&
        other.codigoVerificacao == codigoVerificacao &&
        other.status == status &&
        other.dataCriacao == dataCriacao &&
        other.dataUltimaTentativa == dataUltimaTentativa &&
        other.tentativas == tentativas &&
        other.dataExpiracao == dataExpiracao &&
        other.verificado == verificado;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        usuarioId.hashCode ^
        telefone.hashCode ^
        codigoVerificacao.hashCode ^
        status.hashCode ^
        dataCriacao.hashCode ^
        dataUltimaTentativa.hashCode ^
        tentativas.hashCode ^
        dataExpiracao.hashCode ^
        verificado.hashCode;
  }

  @override
  String toString() {
    return 'VerificacaoTelefone(id: $id, usuarioId: $usuarioId, telefone: $telefone, status: $status, tentativas: $tentativas, verificado: $verificado)';
  }
}

/// Status possíveis para a verificação de telefone
enum StatusVerificacaoTelefone {
  /// Código foi enviado e está aguardando verificação
  codigoEnviado,

  /// Código foi verificado com sucesso
  verificado,

  /// Código expirou
  expirado,

  /// Número máximo de tentativas atingido
  bloqueado,

  /// Falha no envio do código
  falhaEnvio,

  /// Verificação cancelada
  cancelado,
}
