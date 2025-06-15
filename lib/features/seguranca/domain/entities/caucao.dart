/// Entidade que representa uma caução bloqueada
class Caucao {
  final String id;
  final String aluguelId;
  final String locatarioId;
  final String locadorId;
  final String itemId;
  final double valor;
  final StatusCaucao status;
  final DateTime criadaEm;
  final DateTime? liberadaEm;
  final String? motivoLiberacao;
  final String? transacaoId; // ID da transação no gateway de pagamento

  const Caucao({
    required this.id,
    required this.aluguelId,
    required this.locatarioId,
    required this.locadorId,
    required this.itemId,
    required this.valor,
    required this.status,
    required this.criadaEm,
    this.liberadaEm,
    this.motivoLiberacao,
    this.transacaoId,
  });

  Caucao copyWith({
    String? id,
    String? aluguelId,
    String? locatarioId,
    String? locadorId,
    String? itemId,
    double? valor,
    StatusCaucao? status,
    DateTime? criadaEm,
    DateTime? liberadaEm,
    String? motivoLiberacao,
    String? transacaoId,
  }) {
    return Caucao(
      id: id ?? this.id,
      aluguelId: aluguelId ?? this.aluguelId,
      locatarioId: locatarioId ?? this.locatarioId,
      locadorId: locadorId ?? this.locadorId,
      itemId: itemId ?? this.itemId,
      valor: valor ?? this.valor,
      status: status ?? this.status,
      criadaEm: criadaEm ?? this.criadaEm,
      liberadaEm: liberadaEm ?? this.liberadaEm,
      motivoLiberacao: motivoLiberacao ?? this.motivoLiberacao,
      transacaoId: transacaoId ?? this.transacaoId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aluguelId': aluguelId,
      'locatarioId': locatarioId,
      'locadorId': locadorId,
      'itemId': itemId,
      'valor': valor,
      'status': status.name,
      'criadaEm': criadaEm.millisecondsSinceEpoch,
      'liberadaEm': liberadaEm?.millisecondsSinceEpoch,
      'motivoLiberacao': motivoLiberacao,
      'transacaoId': transacaoId,
    };
  }

  factory Caucao.fromMap(Map<String, dynamic> map) {
    return Caucao(
      id: map['id'] ?? '',
      aluguelId: map['aluguelId'] ?? '',
      locatarioId: map['locatarioId'] ?? '',
      locadorId: map['locadorId'] ?? '',
      itemId: map['itemId'] ?? '',
      valor: (map['valor'] ?? 0.0).toDouble(),
      status: StatusCaucao.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusCaucao.pendente,
      ),
      criadaEm: DateTime.fromMillisecondsSinceEpoch(map['criadaEm'] ?? 0),
      liberadaEm: map['liberadaEm'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['liberadaEm'])
          : null,
      motivoLiberacao: map['motivoLiberacao'],
      transacaoId: map['transacaoId'],
    );
  }
}

/// Status possíveis da caução
enum StatusCaucao {
  pendente,     // Aguardando pagamento
  bloqueada,    // Valor bloqueado com sucesso
  liberada,     // Liberada após devolução
  utilizada,    // Utilizada para cobrir danos/multas
  cancelada,    // Cancelada (aluguel cancelado)
}
