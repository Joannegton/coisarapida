/// Representa um problema reportado durante um aluguel
class Problema {
  final String id;
  final String aluguelId;
  final String itemId;
  final String reportadoPorId;
  final String reportadoPorNome;
  final String reportadoContraId; // ID da outra parte (locador ou locatário)
  final TipoProblema tipo;
  final PrioridadeProblema prioridade;
  final String descricao;
  final List<String> fotos;
  final StatusProblema status;
  final DateTime criadoEm;
  final DateTime? resolvidoEm;
  final String? resolucao;

  Problema({
    required this.id,
    required this.aluguelId,
    required this.itemId,
    required this.reportadoPorId,
    required this.reportadoPorNome,
    required this.reportadoContraId,
    required this.tipo,
    required this.prioridade,
    required this.descricao,
    required this.fotos,
    required this.status,
    required this.criadoEm,
    this.resolvidoEm,
    this.resolucao,
  });

  factory Problema.fromMap(Map<String, dynamic> map) {
    return Problema(
      id: map['id'] as String,
      aluguelId: map['aluguelId'] as String,
      itemId: map['itemId'] as String,
      reportadoPorId: map['reportadoPorId'] as String,
      reportadoPorNome: map['reportadoPorNome'] as String,
      reportadoContraId: map['reportadoContraId'] as String,
      tipo: TipoProblema.values.firstWhere(
        (e) => e.toString().split('.').last == map['tipo'],
        orElse: () => TipoProblema.outro,
      ),
      prioridade: PrioridadeProblema.values.firstWhere(
        (e) => e.toString().split('.').last == map['prioridade'],
        orElse: () => PrioridadeProblema.media,
      ),
      descricao: map['descricao'] as String,
      fotos: List<String>.from(map['fotos'] ?? []),
      status: StatusProblema.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => StatusProblema.aberto,
      ),
      criadoEm: DateTime.fromMillisecondsSinceEpoch(map['criadoEm'] as int),
      resolvidoEm: map['resolvidoEm'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['resolvidoEm'] as int)
          : null,
      resolucao: map['resolucao'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aluguelId': aluguelId,
      'itemId': itemId,
      'reportadoPorId': reportadoPorId,
      'reportadoPorNome': reportadoPorNome,
      'reportadoContraId': reportadoContraId,
      'tipo': tipo.toString().split('.').last,
      'prioridade': prioridade.toString().split('.').last,
      'descricao': descricao,
      'fotos': fotos,
      'status': status.toString().split('.').last,
      'criadoEm': criadoEm.millisecondsSinceEpoch,
      'resolvidoEm': resolvidoEm?.millisecondsSinceEpoch,
      'resolucao': resolucao,
    };
  }

  Problema copyWith({
    String? id,
    String? aluguelId,
    String? itemId,
    String? reportadoPorId,
    String? reportadoPorNome,
    String? reportadoContraId,
    TipoProblema? tipo,
    PrioridadeProblema? prioridade,
    String? descricao,
    List<String>? fotos,
    StatusProblema? status,
    DateTime? criadoEm,
    DateTime? resolvidoEm,
    String? resolucao,
  }) {
    return Problema(
      id: id ?? this.id,
      aluguelId: aluguelId ?? this.aluguelId,
      itemId: itemId ?? this.itemId,
      reportadoPorId: reportadoPorId ?? this.reportadoPorId,
      reportadoPorNome: reportadoPorNome ?? this.reportadoPorNome,
      reportadoContraId: reportadoContraId ?? this.reportadoContraId,
      tipo: tipo ?? this.tipo,
      prioridade: prioridade ?? this.prioridade,
      descricao: descricao ?? this.descricao,
      fotos: fotos ?? this.fotos,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      resolvidoEm: resolvidoEm ?? this.resolvidoEm,
      resolucao: resolucao ?? this.resolucao,
    );
  }
}

/// Tipos de problemas que podem ser reportados
enum TipoProblema {
  itemDanificado('Item Danificado', '🔨'),
  itemNaoFunciona('Item Não Funciona', '⚠️'),
  itemDiferente('Item Diferente do Anunciado', '❌'),
  atrasoDevolucao('Atraso na Devolução', '⏰'),
  faltaPecas('Falta de Peças/Acessórios', '🧩'),
  sujeira('Item Sujo/Mal Conservado', '🧹'),
  comunicacao('Problema de Comunicação', '💬'),
  outro('Outro', '📝');

  final String label;
  final String emoji;

  const TipoProblema(this.label, this.emoji);
}

/// Níveis de prioridade do problema
enum PrioridadeProblema {
  baixa('Baixa', '🟢'),
  media('Média', '🟡'),
  alta('Alta', '🟠'),
  urgente('Urgente', '🔴');

  final String label;
  final String emoji;

  const PrioridadeProblema(this.label, this.emoji);
}

/// Status do problema
enum StatusProblema {
  aberto('Aberto', '🔓'),
  emAnalise('Em Análise', '🔍'),
  resolvido('Resolvido', '✅'),
  cancelado('Cancelado', '🚫');

  final String label;
  final String emoji;

  const StatusProblema(this.label, this.emoji);
}
