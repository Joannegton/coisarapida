import 'package:coisarapida/features/vendas/domain/entities/venda.dart';

abstract class VendaRepository {
  Future<void> registrarVenda(Venda venda);
  Future<Venda?> buscarVendaPorId(String id);
  Future<List<Venda>> buscarVendasPorComprador(String compradorId);
  Future<List<Venda>> buscarVendasPorVendedor(String vendedorId);
  Future<void> atualizarStatusPagamento(String vendaId, String status);
}
