enum StatusAluguel {
  solicitado,       // Locatário solicitou o aluguel
  aprovado,         // Locador aprovou a solicitação
  recusado,         // Locador recusou a solicitação
  pagamentoPendente,// Aguardando pagamento do locatário (após aprovação)
  confirmado,       // Pagamento confirmado, aguardando retirada/entrega
  emAndamento,      // Item com o locatário
  devolucaoPendente,// Locatário marcou para devolver
  concluido,        // Item devolvido e tudo OK
  cancelado,        // Aluguel cancelado por uma das partes
  disputa,          // Problema reportado
}

class Aluguel {
  final String id;
  final String itemId;
  final String itemNome;
  final String itemFotoUrl;
  final String locadorId; // Dono do item
  final String locadorNome;
  final String locatarioId; // Quem está alugando
  final String locatarioNome;
  final DateTime dataInicio;
  final DateTime dataFim;
  final double precoTotal;
  final double? caucaoValor; // Valor do caução, se aplicável
  final StatusAluguel status;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final String? observacoesLocatario; // Observações do locatário ao solicitar
  final String? motivoRecusaLocador;  // Motivo se o locador recusar
  final String? contratoId; // ID do contrato assinado, se houver

  Aluguel({
    required this.id,
    required this.itemId,
    required this.itemNome,
    required this.itemFotoUrl,
    required this.locadorId,
    required this.locadorNome,
    required this.locatarioId,
    required this.locatarioNome,
    required this.dataInicio,
    required this.dataFim,
    required this.precoTotal,
    this.caucaoValor,
    required this.status,
    required this.criadoEm,
    this.atualizadoEm,
    this.observacoesLocatario,
    this.motivoRecusaLocador,
    this.contratoId,
  });

  Aluguel copyWith({
    String? id,
    String? itemId,
    String? itemNome,
    String? itemFotoUrl,
    String? locadorId,
    String? locadorNome,
    String? locatarioId,
    String? locatarioNome,
    DateTime? dataInicio,
    DateTime? dataFim,
    double? precoTotal,
    double? caucaoValor,
    StatusAluguel? status,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String? observacoesLocatario,
    String? motivoRecusaLocador,
    String? contratoId,
  }) {
    return Aluguel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemNome: itemNome ?? this.itemNome,
      itemFotoUrl: itemFotoUrl ?? this.itemFotoUrl,
      locadorId: locadorId ?? this.locadorId,
      locadorNome: locadorNome ?? this.locadorNome,
      locatarioId: locatarioId ?? this.locatarioId,
      locatarioNome: locatarioNome ?? this.locatarioNome,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      precoTotal: precoTotal ?? this.precoTotal,
      caucaoValor: caucaoValor ?? this.caucaoValor,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      observacoesLocatario: observacoesLocatario ?? this.observacoesLocatario,
      motivoRecusaLocador: motivoRecusaLocador ?? this.motivoRecusaLocador,
      contratoId: contratoId ?? this.contratoId,
    );
  }
}