/// Entidade que representa uma denúncia de problema no aluguel
class Denuncia {
  final String id;
  final String aluguelId;
  final String denuncianteId;
  final String denunciadoId;
  final TipoDenuncia tipo;
  final String descricao;
  final List<String> evidencias;
  final StatusDenuncia status;
  final DateTime criadaEm;
  final DateTime? resolvidaEm;
  final String? resolucao;
  final String? moderadorId;

  const Denuncia({
    required this.id,
    required this.aluguelId,
    required this.denuncianteId,
    required this.denunciadoId,
    required this.tipo,
    required this.descricao,
    required this.evidencias,
    required this.status,
    required this.criadaEm,
    this.resolvidaEm,
    this.resolucao,
    this.moderadorId,
  });

  Denuncia copyWith({
    String? id,
    String? aluguelId,
    String? denuncianteId,
    String? denunciadoId,
    TipoDenuncia? tipo,
    String? descricao,
    List<String>? evidencias,
    StatusDenuncia? status,
    DateTime? criadaEm,
    DateTime? resolvidaEm,
    String? resolucao,
    String? moderadorId,
  }) {
    return Denuncia(
      id: id ?? this.id,
      aluguelId: aluguelId ?? this.aluguelId,
      denuncianteId: denuncianteId ?? this.denuncianteId,
      denunciadoId: denunciadoId ?? this.denunciadoId,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      evidencias: evidencias ?? this.evidencias,
      status: status ?? this.status,
      criadaEm: criadaEm ?? this.criadaEm,
      resolvidaEm: resolvidaEm ?? this.resolvidaEm,
      resolucao: resolucao ?? this.resolucao,
      moderadorId: moderadorId ?? this.moderadorId,
    );
  }
}

/// Tipos de denúncia possíveis
enum TipoDenuncia {
  naoDevolucao,
  atraso,
  danos,
  usoIndevido,
  comportamentoInadequado,
  outros,
}

/// Status da denúncia
enum StatusDenuncia {
  pendente,
  emAnalise,
  resolvida,
  rejeitada,
}
