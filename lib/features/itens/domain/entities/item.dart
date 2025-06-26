/// Entidade que representa um item disponível para aluguel
class Item {
  final String id;
  final String nome;
  final String descricao;
  final String categoria;
  final List<String> fotos;
  final double precoPorDia;
  final double? precoPorHora;
  final double? valorCaucao;
  final String? regrasUso;
  final bool disponivel;
  final bool aprovacaoAutomatica;
  final String proprietarioId;
  final String proprietarioNome;
  final double? proprietarioReputacao;
  final Localizacao localizacao;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  
  // Estatísticas
  final double avaliacao;
  final int totalAlugueis;
  final int visualizacoes;

  const Item({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.fotos,
    required this.precoPorDia,
    this.precoPorHora,
    this.valorCaucao,
    this.regrasUso,
    required this.disponivel,
    required this.aprovacaoAutomatica,
    required this.proprietarioId,
    required this.proprietarioNome,
    this.proprietarioReputacao,
    required this.localizacao,
    required this.criadoEm,
    this.atualizadoEm,
    this.avaliacao = 0.0,
    this.totalAlugueis = 0,
    this.visualizacoes = 0,
  });

  Item copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? categoria,
    List<String>? fotos,
    double? precoPorDia,
    double? precoPorHora,
    double? caucao,
    String? regrasUso,
    bool? disponivel,
    bool? aprovacaoAutomatica,
    String? proprietarioId,
    String? proprietarioNome,
    double? proprietarioReputacao,
    Localizacao? localizacao,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    double? avaliacao,
    int? totalAlugueis,
    int? visualizacoes,
  }) {
    return Item(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      fotos: fotos ?? this.fotos,
      precoPorDia: precoPorDia ?? this.precoPorDia,
      precoPorHora: precoPorHora ?? this.precoPorHora,
      valorCaucao: caucao ?? this.valorCaucao,
      regrasUso: regrasUso ?? this.regrasUso,
      disponivel: disponivel ?? this.disponivel,
      aprovacaoAutomatica: aprovacaoAutomatica ?? this.aprovacaoAutomatica,
      proprietarioId: proprietarioId ?? this.proprietarioId,
      proprietarioNome: proprietarioNome ?? this.proprietarioNome,
      proprietarioReputacao: proprietarioReputacao ?? this.proprietarioReputacao,
      localizacao: localizacao ?? this.localizacao,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      avaliacao: avaliacao ?? this.avaliacao,
      totalAlugueis: totalAlugueis ?? this.totalAlugueis,
      visualizacoes: visualizacoes ?? this.visualizacoes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Entidade para localização do item
class Localizacao {
  final double latitude;
  final double longitude;
  final String endereco;
  final String bairro;
  final String cidade;
  final String estado;

  const Localizacao({
    required this.latitude,
    required this.longitude,
    required this.endereco,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  // Add toMap and fromMap for Localizacao if it's to be a nested object
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'endereco': endereco,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
    };
  }

  factory Localizacao.fromMap(Map<String, dynamic> map) {
    return Localizacao(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      endereco: map['endereco'] as String? ?? '',
      bairro: map['bairro'] as String? ?? '',
      cidade: map['cidade'] as String? ?? '',
      estado: map['estado'] as String? ?? '',
    );
  }
}
