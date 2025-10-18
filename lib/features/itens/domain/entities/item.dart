import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';

class Item {
  final String id;
  final String nome;
  final String descricao;
  final String categoria;
  final List<String> fotos;
  final double precoPorDia;
  final double? precoPorHora;
  final double? precoVenda;
  final TipoItem tipo;
  final EstadoItem estado;
  final double? valorCaucao;
  final String? regrasUso;
  final bool disponivel;
  final bool aprovacaoAutomatica;
  final String proprietarioId;
  final String proprietarioNome;
  final double? proprietarioReputacao;
  final Endereco localizacao;
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
    this.precoVenda,
    this.tipo = TipoItem.aluguel,
    this.estado = EstadoItem.usado,
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
    double? precoVenda,
    TipoItem? tipo,
    EstadoItem? estado,
    double? caucao,
    String? regrasUso,
    bool? disponivel,
    bool? aprovacaoAutomatica,
    String? proprietarioId,
    String? proprietarioNome,
    double? proprietarioReputacao,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    double? avaliacao,
    Endereco? localizacao,
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
      precoVenda: precoVenda ?? this.precoVenda,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      valorCaucao: caucao ?? this.valorCaucao,
      regrasUso: regrasUso ?? this.regrasUso,
      disponivel: disponivel ?? this.disponivel,
      aprovacaoAutomatica: aprovacaoAutomatica ?? this.aprovacaoAutomatica,
      proprietarioId: proprietarioId ?? this.proprietarioId,
      proprietarioNome: proprietarioNome ?? this.proprietarioNome,
      proprietarioReputacao:
          proprietarioReputacao ?? this.proprietarioReputacao,
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

/// Enum para tipo do item
enum TipoItem {
  aluguel,
  venda,
  ambos, // Item pode ser alugado ou vendido
}

/// Enum para estado do item
enum EstadoItem {
  novo,
  seminovo,
  usado,
  precisaReparo,
}

