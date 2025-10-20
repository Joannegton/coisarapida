/// Entidade que representa um contrato digital de aluguel
class ContratoDigital {
  final String id;  
  final String aluguelId;
  final String locatarioId;
  final String locadorId;
  final String itemId;
  final String conteudoHtml;
  final DateTime criadoEm;
  final AceiteContrato? aceiteLocatario;
  final AceiteContrato? aceiteLocador;
  final String versaoContrato;

  const ContratoDigital({
    required this.id,
    required this.aluguelId,
    required this.locatarioId,
    required this.locadorId,
    required this.itemId,
    required this.conteudoHtml,
    required this.criadoEm,
    this.aceiteLocatario,
    this.aceiteLocador,
    required this.versaoContrato,
  });

  bool get foiAceito => aceiteLocatario != null && aceiteLocador != null;

  ContratoDigital copyWith({
    String? id,
    String? aluguelId,
    String? locatarioId,
    String? locadorId,
    String? itemId,
    String? conteudoHtml,
    DateTime? criadoEm,
    AceiteContrato? aceiteLocatario,
    AceiteContrato? aceiteLocador,
    String? versaoContrato,
  }) {
    return ContratoDigital(
      id: id ?? this.id,
      aluguelId: aluguelId ?? this.aluguelId,
      locatarioId: locatarioId ?? this.locatarioId,
      locadorId: locadorId ?? this.locadorId,
      itemId: itemId ?? this.itemId,
      conteudoHtml: conteudoHtml ?? this.conteudoHtml,
      criadoEm: criadoEm ?? this.criadoEm,
      aceiteLocatario: aceiteLocatario ?? this.aceiteLocatario,
      aceiteLocador: aceiteLocador ?? this.aceiteLocador,
      versaoContrato: versaoContrato ?? this.versaoContrato,
    );
  }
}

/// Entidade que representa o aceite de um contrato
class AceiteContrato {
  final DateTime dataHora; 
  final String enderecoIp;
  final String userAgent;
  final String assinaturaDigital;

  const AceiteContrato({
    required this.dataHora,
    required this.enderecoIp,
    required this.userAgent,
    required this.assinaturaDigital,
  });

  /// Método para serialização - mantido por compatibilidade com código existente
  /// Considere mover para um AceiteContratoModel no futuro
  Map<String, dynamic> toMap() {
    return {
      'dataHora': dataHora.millisecondsSinceEpoch,
      'enderecoIp': enderecoIp,
      'userAgent': userAgent,
      'assinaturaDigital': assinaturaDigital,
    };
  }

  /// Factory para deserialização - mantido por compatibilidade
  /// Considere mover para um AceiteContratoModel no futuro
  factory AceiteContrato.fromMap(Map<String, dynamic> map) {
    return AceiteContrato(
      dataHora: map['dataHora'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dataHora'])
          : DateTime.now(),
      enderecoIp: map['enderecoIp'] ?? '',
      userAgent: map['userAgent'] ?? '',
      assinaturaDigital: map['assinaturaDigital'] ?? '',
    );
  }
}
