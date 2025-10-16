import 'dart:io';

/// Entidade que representa uma verificação de residência
class VerificacaoResidencia {
  /// ID único da verificação
  final String id;

  /// ID do usuário que está sendo verificado
  final String usuarioId;

  /// Endereço sendo verificado
  final EnderecoVerificacao endereco;

  /// URL da imagem do comprovante de residência
  final String? comprovanteUrl;

  /// Status da verificação
  final StatusVerificacaoResidencia status;

  /// Data de criação da solicitação
  final DateTime dataCriacao;

  /// Data da última atualização
  final DateTime? dataAtualizacao;

  /// ID do moderador que analisou (se aplicável)
  final String? moderadorId;

  /// Observações do moderador
  final String? observacoesModerador;

  /// Se a verificação foi aprovada
  final bool aprovado;

  const VerificacaoResidencia({
    required this.id,
    required this.usuarioId,
    required this.endereco,
    this.comprovanteUrl,
    required this.status,
    required this.dataCriacao,
    this.dataAtualizacao,
    this.moderadorId,
    this.observacoesModerador,
    required this.aprovado,
  });

  /// Cria uma cópia da entidade com campos modificados
  VerificacaoResidencia copyWith({
    String? id,
    String? usuarioId,
    EnderecoVerificacao? endereco,
    String? comprovanteUrl,
    StatusVerificacaoResidencia? status,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    String? moderadorId,
    String? observacoesModerador,
    bool? aprovado,
  }) {
    return VerificacaoResidencia(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      endereco: endereco ?? this.endereco,
      comprovanteUrl: comprovanteUrl ?? this.comprovanteUrl,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      moderadorId: moderadorId ?? this.moderadorId,
      observacoesModerador: observacoesModerador ?? this.observacoesModerador,
      aprovado: aprovado ?? this.aprovado,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VerificacaoResidencia &&
        other.id == id &&
        other.usuarioId == usuarioId &&
        other.endereco == endereco &&
        other.comprovanteUrl == comprovanteUrl &&
        other.status == status &&
        other.dataCriacao == dataCriacao &&
        other.dataAtualizacao == dataAtualizacao &&
        other.moderadorId == moderadorId &&
        other.observacoesModerador == observacoesModerador &&
        other.aprovado == aprovado;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        usuarioId.hashCode ^
        endereco.hashCode ^
        comprovanteUrl.hashCode ^
        status.hashCode ^
        dataCriacao.hashCode ^
        dataAtualizacao.hashCode ^
        moderadorId.hashCode ^
        observacoesModerador.hashCode ^
        aprovado.hashCode;
  }

  @override
  String toString() {
    return 'VerificacaoResidencia(id: $id, usuarioId: $usuarioId, endereco: $endereco, status: $status, aprovado: $aprovado)';
  }
}

/// Endereço usado na verificação de residência
class EnderecoVerificacao {
  /// CEP do endereço
  final String cep;

  /// Rua/avenida
  final String rua;

  /// Número da residência
  final String numero;

  /// Complemento (opcional)
  final String? complemento;

  /// Bairro
  final String bairro;

  /// Cidade
  final String cidade;

  /// Estado (UF)
  final String estado;

  const EnderecoVerificacao({
    required this.cep,
    required this.rua,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  /// Cria uma cópia do endereço com campos modificados
  EnderecoVerificacao copyWith({
    String? cep,
    String? rua,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
  }) {
    return EnderecoVerificacao(
      cep: cep ?? this.cep,
      rua: rua ?? this.rua,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EnderecoVerificacao &&
        other.cep == cep &&
        other.rua == rua &&
        other.numero == numero &&
        other.complemento == complemento &&
        other.bairro == bairro &&
        other.cidade == cidade &&
        other.estado == estado;
  }

  @override
  int get hashCode {
    return cep.hashCode ^
        rua.hashCode ^
        numero.hashCode ^
        complemento.hashCode ^
        bairro.hashCode ^
        cidade.hashCode ^
        estado.hashCode;
  }

  @override
  String toString() {
    return '$rua, $numero${complemento != null ? ', $complemento' : ''} - $bairro, $cidade - $estado, CEP: $cep';
  }

  /// Converte para um mapa para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'cep': cep,
      'rua': rua,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
    };
  }

  /// Cria um EnderecoVerificacao a partir de um mapa do Firestore
  factory EnderecoVerificacao.fromMap(Map<String, dynamic> map) {
    return EnderecoVerificacao(
      cep: map['cep'] as String? ?? '',
      rua: map['rua'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      complemento: map['complemento'] as String?,
      bairro: map['bairro'] as String? ?? '',
      cidade: map['cidade'] as String? ?? '',
      estado: map['estado'] as String? ?? '',
    );
  }
}

/// Status possíveis para a verificação de residência
enum StatusVerificacaoResidencia {
  /// Solicitação enviada, aguardando análise
  pendente,

  /// Em análise por um moderador
  emAnalise,

  /// Aprovada pelo moderador
  aprovada,

  /// Rejeitada pelo moderador
  rejeitada,

  /// Documento solicitado para complementação
  documentoSolicitado,

  /// Verificação cancelada pelo usuário
  cancelada,

  /// Erro no processamento
  erro,
}
