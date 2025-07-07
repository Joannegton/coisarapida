class Venda {
  final String id;
  final String itemId;
  final String itemNome;
  final String itemFotoUrl;
  final String vendedorId;
  final String vendedorNome;
  final String compradorId;
  final String compradorNome;
  final double valorPago;
  final String metodoPagamento;
  final String transacaoId;
  final DateTime dataVenda;

  const Venda({
    required this.id,
    required this.itemId,
    required this.itemNome,
    required this.itemFotoUrl,
    required this.vendedorId,
    required this.vendedorNome,
    required this.compradorId,
    required this.compradorNome,
    required this.valorPago,
    required this.metodoPagamento,
    required this.transacaoId,
    required this.dataVenda,
  });
}
