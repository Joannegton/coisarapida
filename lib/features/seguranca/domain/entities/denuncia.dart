/// Entidade que representa uma denúncia de problema no aluguel
class Denuncia {
  final String id;
  final String aluguelId;
  final String denuncianteId;
  final String denunciadoId;
  final TipoDenuncia tipo;
  final String descricao;
  final List<String> evidencias; // URLs das fotos/documentos
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aluguelId': aluguelId,
      'denuncianteId': denuncianteId,
      'denunciadoId': denunciadoId,
      'tipo': tipo.name,
      'descricao': descricao,
      'evidencias': evidencias,
      'status': status.name,
      'criadaEm': criadaEm.millisecondsSinceEpoch,
      'resolvidaEm': resolvidaEm?.millisecondsSinceEpoch,
      'resolucao': resolucao,
      'moderadorId': moderadorId,
    };
  }

  factory Denuncia.fromMap(Map<String, dynamic> map) {
    return Denuncia(
      id: map['id'] ?? '',
      aluguelId: map['aluguelId'] ?? '',
      denuncianteId: map['denuncianteId'] ?? '',
      denunciadoId: map['denunciadoId'] ?? '',
      tipo: TipoDenuncia.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoDenuncia.outros,
      ),
      descricao: map['descricao'] ?? '',
      evidencias: List<String>.from(map['evidencias'] ?? []),
      status: StatusDenuncia.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusDenuncia.pendente,
      ),
      criadaEm: DateTime.fromMillisecondsSinceEpoch(map['criadaEm'] ?? 0),
      resolvidaEm: map['resolvidaEm'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['resolvidaEm'])
          : null,
      resolucao: map['resolucao'],
      moderadorId: map['moderadorId'],
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
