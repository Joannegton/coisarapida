/// Entidade que representa um contrato digital de aluguel
class ContratoDigital {
  final String id;
  final String aluguelId;
  final String locatarioId;
  final String locadorId;
  final String itemId;
  final String conteudoHtml;
  final DateTime criadoEm;
  final AceiteContrato? aceite;
  final String versaoContrato; // Para controle de versões

  const ContratoDigital({
    required this.id,
    required this.aluguelId,
    required this.locatarioId,
    required this.locadorId,
    required this.itemId,
    required this.conteudoHtml,
    required this.criadoEm,
    this.aceite,
    required this.versaoContrato,
  });

  bool get foiAceito => aceite != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aluguelId': aluguelId,
      'locatarioId': locatarioId,
      'locadorId': locadorId,
      'itemId': itemId,
      'conteudoHtml': conteudoHtml,
      'criadoEm': criadoEm.millisecondsSinceEpoch,
      'aceite': aceite?.toMap(),
      'versaoContrato': versaoContrato,
    };
  }

  factory ContratoDigital.fromMap(Map<String, dynamic> map) {
    return ContratoDigital(
      id: map['id'] ?? '',
      aluguelId: map['aluguelId'] ?? '',
      locatarioId: map['locatarioId'] ?? '',
      locadorId: map['locadorId'] ?? '',
      itemId: map['itemId'] ?? '',
      conteudoHtml: map['conteudoHtml'] ?? '',
      criadoEm: DateTime.fromMillisecondsSinceEpoch(map['criadoEm'] ?? 0),
      aceite: map['aceite'] != null ? AceiteContrato.fromMap(map['aceite']) : null,
      versaoContrato: map['versaoContrato'] ?? '1.0',
    );
  }
}

/// Entidade que representa o aceite de um contrato
class AceiteContrato {
  final DateTime dataHora;
  final String enderecoIp;
  final String userAgent;
  final String assinaturaDigital; // Hash do aceite

  const AceiteContrato({
    required this.dataHora,
    required this.enderecoIp,
    required this.userAgent,
    required this.assinaturaDigital,
  });

  Map<String, dynamic> toMap() {
    return {
      'dataHora': dataHora.millisecondsSinceEpoch,
      'enderecoIp': enderecoIp,
      'userAgent': userAgent,
      'assinaturaDigital': assinaturaDigital,
    };
  }

  factory AceiteContrato.fromMap(Map<String, dynamic> map) {
    return AceiteContrato(
      dataHora: DateTime.fromMillisecondsSinceEpoch(map['dataHora'] ?? 0),
      enderecoIp: map['enderecoIp'] ?? '',
      userAgent: map['userAgent'] ?? '',
      assinaturaDigital: map['assinaturaDigital'] ?? '',
    );
  }
}
