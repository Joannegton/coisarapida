import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String versaoContrato;

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

  // Método copyWith para facilitar atualizações
  ContratoDigital copyWith({
    String? id,
    String? aluguelId,
    String? locatarioId,
    String? locadorId,
    String? itemId,
    String? conteudoHtml,
    DateTime? criadoEm,
    AceiteContrato? aceite,
    String? versaoContrato,
    bool? aceito,
  }) {
    return ContratoDigital(
      id: id ?? this.id,
      aluguelId: aluguelId ?? this.aluguelId,
      locatarioId: locatarioId ?? this.locatarioId,
      locadorId: locadorId ?? this.locadorId,
      itemId: itemId ?? this.itemId,
      conteudoHtml: conteudoHtml ?? this.conteudoHtml,
      criadoEm: criadoEm ?? this.criadoEm,
      aceite: aceite ?? this.aceite,
      versaoContrato: versaoContrato ?? this.versaoContrato,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aluguelId': aluguelId,
      'locatarioId': locatarioId,
      'locadorId': locadorId,
      'itemId': itemId,
      'conteudoHtml': conteudoHtml,
      // Para a criação inicial do contrato, sempre usar FieldValue.serverTimestamp()
      // Se este toMap for usado APENAS para criação, simplifique para:
      'criadoEm': FieldValue.serverTimestamp(), 
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
      criadoEm: map['criadoEm'] is Timestamp 
          ? (map['criadoEm'] as Timestamp).toDate() 
          : DateTime.fromMillisecondsSinceEpoch(map['criadoEm'] ?? 0), // Fallback para o formato antigo se necessário
      aceite: map['aceite'] != null ? AceiteContrato.fromMap(map['aceite']) : null,
      versaoContrato: map['versaoContrato'] ?? '1.0',
    );
  }
}

/// Entidade que representa o aceite de um contrato
class AceiteContrato {
  // O valor de dataHora no construtor é para o objeto Dart, mas no toMap usaremos FieldValue.serverTimestamp()
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

  Map<String, dynamic> toMap() {
    return {
      'dataHora': FieldValue.serverTimestamp(), // Sempre usar FieldValue.serverTimestamp() para o aceite
      'enderecoIp': enderecoIp,
      'userAgent': userAgent,
      'assinaturaDigital': assinaturaDigital,
    };
  }

  factory AceiteContrato.fromMap(Map<String, dynamic> map) {
    return AceiteContrato(
      dataHora: map['dataHora'] is Timestamp 
          ? (map['dataHora'] as Timestamp).toDate() 
          : DateTime.fromMillisecondsSinceEpoch(map['dataHora'] ?? 0), // Fallback
      enderecoIp: map['enderecoIp'] ?? '',
      userAgent: map['userAgent'] ?? '',
      assinaturaDigital: map['assinaturaDigital'] ?? '',
    );
  }
}
