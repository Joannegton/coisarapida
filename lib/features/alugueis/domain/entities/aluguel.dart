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

/// Status possíveis da caução integrada ao aluguel
enum StatusCaucaoAluguel {
  pendentePagamento, // Aguardando pagamento/bloqueio da caução
  bloqueada,         // Valor bloqueado com sucesso
  liberada,          // Caução liberada após devolução
  utilizadaParcialmente, // Parte da caução utilizada
  utilizadaTotalmente,   // Toda a caução utilizada
  naoAplicavel,      // Se o item não exigir caução
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

  // Campos da Caução Integrados
  final StatusCaucaoAluguel? caucaoStatus;
  final String? caucaoMetodoPagamento;
  final String? caucaoTransacaoId;
  final DateTime? caucaoDataBloqueio;
  final DateTime? caucaoDataLiberacao;
  final String? caucaoMotivoRetencao; // Se parte da caução for retida
  final double? caucaoValorRetido;    // Valor retido da caução


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
    this.caucaoStatus,
    this.caucaoMetodoPagamento,
    this.caucaoTransacaoId,
    this.caucaoDataBloqueio,
    this.caucaoDataLiberacao,
    this.caucaoMotivoRetencao,
    this.caucaoValorRetido,
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
    StatusCaucaoAluguel? caucaoStatus,
    String? caucaoMetodoPagamento,
    String? caucaoTransacaoId,
    DateTime? caucaoDataBloqueio,
    DateTime? caucaoDataLiberacao,
    String? caucaoMotivoRetencao,
    double? caucaoValorRetido,
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
      caucaoStatus: caucaoStatus ?? this.caucaoStatus,
      caucaoMetodoPagamento: caucaoMetodoPagamento ?? this.caucaoMetodoPagamento,
      caucaoTransacaoId: caucaoTransacaoId ?? this.caucaoTransacaoId,
      caucaoDataBloqueio: caucaoDataBloqueio ?? this.caucaoDataBloqueio,
      caucaoDataLiberacao: caucaoDataLiberacao ?? this.caucaoDataLiberacao,
      caucaoMotivoRetencao: caucaoMotivoRetencao ?? this.caucaoMotivoRetencao,
      caucaoValorRetido: caucaoValorRetido ?? this.caucaoValorRetido,
    );
  }
}