import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';
import '../../domain/entities/item.dart';

class ItemModel extends Item {
  ItemModel({
    required super.id,
    required super.nome,
    required super.descricao,
    required super.categoria,
    required super.fotos,
    required super.precoPorDia,
    super.precoPorHora,
    super.precoVenda,
    required super.tipo,
    required super.estado,
    super.valorCaucao,
    super.regrasUso,
    required super.disponivel,
    required super.aprovacaoAutomatica,
    required super.proprietarioId,
    required super.proprietarioNome,
    super.proprietarioReputacao,
    required super.localizacao,
    required super.criadoEm,
    super.atualizadoEm,
    super.avaliacao,
    super.totalAlugueis,
    super.visualizacoes,
  });

  factory ItemModel.fromEntity(Item entity) {
    return ItemModel(
      id: entity.id,
      nome: entity.nome,
      descricao: entity.descricao,
      categoria: entity.categoria,
      fotos: entity.fotos,
      precoPorDia: entity.precoPorDia,
      precoPorHora: entity.precoPorHora,
      precoVenda: entity.precoVenda,
      tipo: entity.tipo,
      estado: entity.estado,
      valorCaucao: entity.valorCaucao,
      regrasUso: entity.regrasUso,
      disponivel: entity.disponivel,
      aprovacaoAutomatica: entity.aprovacaoAutomatica,
      proprietarioId: entity.proprietarioId,
      proprietarioNome: entity.proprietarioNome,
      proprietarioReputacao: entity.proprietarioReputacao,
      localizacao: entity.localizacao,
      criadoEm: entity.criadoEm,
      atualizadoEm: entity.atualizadoEm,
      avaliacao: entity.avaliacao,
      totalAlugueis: entity.totalAlugueis,
      visualizacoes: entity.visualizacoes,
    );
  }

  static TipoItem _tipoItemFromString(String? tipo) {
    return TipoItem.values.firstWhere(
      (e) => e.name == tipo,
      orElse: () => TipoItem.aluguel, // Padrão de segurança
    );
  }

  static EstadoItem _estadoItemFromString(String? estado) {
    return EstadoItem.values.firstWhere(
      (e) => e.name == estado,
      orElse: () => EstadoItem.usado, // Padrão de segurança
    );
  }

  factory ItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      // Ou lide com isso de outra forma, como lançar uma exceção específica
      throw Exception("Documento ${doc.id} não encontrado ou dados nulos.");
    }
    return ItemModel(
      id: doc.id,
      nome: data['nome'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      categoria: data['categoria'] as String? ?? '',
      fotos: List<String>.from(data['fotos'] as List? ?? []),
      precoPorDia: (data['precoPorDia'] as num?)?.toDouble() ?? 0.0,
      precoVenda: (data['precoVenda'] as num?)?.toDouble(),
      tipo: _tipoItemFromString(data['tipo'] as String?),
      estado: _estadoItemFromString(data['estado'] as String?),
      precoPorHora: (data['precoPorHora'] as num?)?.toDouble(),
      valorCaucao: (data['caucao'] as num?)?.toDouble(),
      regrasUso: data['regrasUso'] as String?,
      disponivel: data['disponivel'] as bool? ?? true,
      aprovacaoAutomatica: data['aprovacaoAutomatica'] as bool? ?? false,
      proprietarioId: data['proprietarioId'] as String? ?? '',
      proprietarioNome: data['proprietarioNome'] as String? ?? '',
      proprietarioReputacao:
          (data['proprietarioReputacao'] as num?)?.toDouble(),
      localizacao: Endereco.fromMap(
          data['localizacao'] as Map<String, dynamic>? ?? {}),
      criadoEm: (data['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      atualizadoEm: (data['atualizadoEm'] as Timestamp?)?.toDate(),
      avaliacao: (data['avaliacao'] as num?)?.toDouble() ?? 0.0,
      totalAlugueis: data['totalAlugueis'] as int? ?? 0,
      visualizacoes: data['visualizacoes'] as int? ?? 0,
    );
  }

  factory ItemModel.fromMap(Map<String, dynamic> map, String id) {
    return ItemModel(
      id: id,
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      categoria: map['categoria'] ?? '',
      fotos: List<String>.from(map['fotos'] ?? []),
      precoPorDia: (map['precoPorDia'] as num?)?.toDouble() ?? 0.0,
      precoVenda: (map['precoVenda'] as num?)?.toDouble(),
      tipo: _tipoItemFromString(map['tipo'] as String?),
      estado: _estadoItemFromString(map['estado'] as String?),
      precoPorHora: (map['precoPorHora'] as num?)?.toDouble(),
      valorCaucao: (map['caucao'] as num?)?.toDouble(),
      regrasUso: map['regrasUso'],
      disponivel: map['disponivel'] ?? true,
      aprovacaoAutomatica: map['aprovacaoAutomatica'] ?? false,
      proprietarioId: map['proprietarioId'] ?? '',
      proprietarioNome: map['proprietarioNome'] ?? '',
      proprietarioReputacao: (map['proprietarioReputacao'] as num?)?.toDouble(),
      localizacao: Endereco.fromMap(map['localizacao'] ?? {}),
      criadoEm: (map['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      atualizadoEm: (map['atualizadoEm'] as Timestamp?)?.toDate(),
      avaliacao: (map['avaliacao'] as num?)?.toDouble() ?? 0.0,
      totalAlugueis: map['totalAlugueis'] ?? 0,
      visualizacoes: map['visualizacoes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'categoria': categoria,
      'fotos': fotos,
      'precoPorDia': precoPorDia,
      'precoVenda': precoVenda,
      'tipo': tipo.name,
      'estado': estado.name,
      'precoPorHora': precoPorHora,
      'caucao': valorCaucao,
      'regrasUso': regrasUso,
      'disponivel': disponivel,
      'aprovacaoAutomatica': aprovacaoAutomatica,
      'proprietarioId': proprietarioId,
      'proprietarioNome': proprietarioNome,
      'proprietarioReputacao': proprietarioReputacao,
      'localizacao': localizacao.toMap(),
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
      'avaliacao': avaliacao,
      'totalAlugueis': totalAlugueis,
      'visualizacoes': visualizacoes,
    };
  }

  /// Método específico para atualização (não altera criadoEm e campos imutáveis)
  Map<String, dynamic> toMapForUpdate() {
    return {
      'nome': nome,
      'descricao': descricao,
      'categoria': categoria,
      'fotos': fotos,
      'precoPorDia': precoPorDia,
      'precoVenda': precoVenda,
      'tipo': tipo.name,
      'estado': estado.name,
      'precoPorHora': precoPorHora,
      'caucao': valorCaucao,
      'regrasUso': regrasUso,
      'disponivel': disponivel,
      'aprovacaoAutomatica': aprovacaoAutomatica,
      'localizacao': localizacao.toMap(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }
}
