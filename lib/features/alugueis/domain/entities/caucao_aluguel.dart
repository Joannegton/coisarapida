enum StatusCaucaoAluguel {
  pendentePagamento, // Aguardando pagamento/bloqueio da caução
  bloqueada, // Valor bloqueado com sucesso
  liberada, // Caução liberada após devolução
  utilizadaParcialmente, // Parte da caução utilizada
  utilizadaTotalmente, // Toda a caução utilizada
  naoAplicavel, // Se o item não exigir caução
}

class CaucaoAluguel {
  final double valor;
  final StatusCaucaoAluguel status;
  final String? metodoPagamento; //TODO arrumar na implementação
  final String? transacaoId;
  final DateTime? dataBloqueio;
  final DateTime? dataLiberacao;
  final String? motivoRetencao;
  final double? valorRetido;

  CaucaoAluguel({
    required this.valor,
    required this.status,
    this.metodoPagamento,
    this.transacaoId,
    this.dataBloqueio,
    this.dataLiberacao,
    this.motivoRetencao,
    this.valorRetido,
  });

  CaucaoAluguel copyWith({
    double? valor,
    StatusCaucaoAluguel? status,
    String? metodoPagamento,
    String? transacaoId,
    DateTime? dataBloqueio,
    DateTime? dataLiberacao,
    String? motivoRetencao,
    double? valorRetido,
  }) {
    return CaucaoAluguel(
      valor: valor ?? this.valor,
      status: status ?? this.status,
      metodoPagamento: metodoPagamento ?? this.metodoPagamento,
      transacaoId: transacaoId ?? this.transacaoId,
      dataBloqueio: dataBloqueio ?? this.dataBloqueio,
      dataLiberacao: dataLiberacao ?? this.dataLiberacao,
      motivoRetencao: motivoRetencao ?? this.motivoRetencao,
      valorRetido: valorRetido ?? this.valorRetido,
    );
  }
}
