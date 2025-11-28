import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/vendas/domain/entities/venda.dart';
import 'package:coisarapida/features/vendas/domain/repositories/venda_repository.dart';

class VendaRepositoryImpl implements VendaRepository {
  final FirebaseFirestore _firestore;

  VendaRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> registrarVenda(Venda venda) async {
    await _firestore.collection('vendas').doc(venda.id).set({
      'id': venda.id,
      'itemId': venda.itemId,
      'itemNome': venda.itemNome,
      'itemFotoUrl': venda.itemFotoUrl,
      'vendedorId': venda.vendedorId,
      'vendedorNome': venda.vendedorNome,
      'compradorId': venda.compradorId,
      'compradorNome': venda.compradorNome,
      'valorPago': venda.valorPago,
      'metodoPagamento': venda.metodoPagamento,
      'transacaoId': venda.transacaoId,
      'dataVenda': venda.dataVenda,
      'statusPagamento': venda.statusPagamento ?? 'pendente',
      'dataPagamento': venda.dataPagamento,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Venda?> buscarVendaPorId(String id) async {
    final doc = await _firestore.collection('vendas').doc(id).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return Venda(
      id: data['id'],
      itemId: data['itemId'],
      itemNome: data['itemNome'],
      itemFotoUrl: data['itemFotoUrl'],
      vendedorId: data['vendedorId'],
      vendedorNome: data['vendedorNome'],
      compradorId: data['compradorId'],
      compradorNome: data['compradorNome'],
      valorPago: (data['valorPago'] as num).toDouble(),
      metodoPagamento: data['metodoPagamento'],
      transacaoId: data['transacaoId'],
      dataVenda: (data['dataVenda'] as Timestamp).toDate(),
      statusPagamento: data['statusPagamento'],
      dataPagamento: data['dataPagamento'] != null
          ? (data['dataPagamento'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  Future<List<Venda>> buscarVendasPorComprador(String compradorId) async {
    final snapshot = await _firestore
        .collection('vendas')
        .where('compradorId', isEqualTo: compradorId)
        .orderBy('dataVenda', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Venda(
        id: data['id'],
        itemId: data['itemId'],
        itemNome: data['itemNome'],
        itemFotoUrl: data['itemFotoUrl'],
        vendedorId: data['vendedorId'],
        vendedorNome: data['vendedorNome'],
        compradorId: data['compradorId'],
        compradorNome: data['compradorNome'],
        valorPago: (data['valorPago'] as num).toDouble(),
        metodoPagamento: data['metodoPagamento'],
        transacaoId: data['transacaoId'],
        dataVenda: (data['dataVenda'] as Timestamp).toDate(),
        statusPagamento: data['statusPagamento'],
        dataPagamento: data['dataPagamento'] != null
            ? (data['dataPagamento'] as Timestamp).toDate()
            : null,
      );
    }).toList();
  }

  @override
  Future<List<Venda>> buscarVendasPorVendedor(String vendedorId) async {
    final snapshot = await _firestore
        .collection('vendas')
        .where('vendedorId', isEqualTo: vendedorId)
        .orderBy('dataVenda', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Venda(
        id: data['id'],
        itemId: data['itemId'],
        itemNome: data['itemNome'],
        itemFotoUrl: data['itemFotoUrl'],
        vendedorId: data['vendedorId'],
        vendedorNome: data['vendedorNome'],
        compradorId: data['compradorId'],
        compradorNome: data['compradorNome'],
        valorPago: (data['valorPago'] as num).toDouble(),
        metodoPagamento: data['metodoPagamento'],
        transacaoId: data['transacaoId'],
        dataVenda: (data['dataVenda'] as Timestamp).toDate(),
        statusPagamento: data['statusPagamento'],
        dataPagamento: data['dataPagamento'] != null
            ? (data['dataPagamento'] as Timestamp).toDate()
            : null,
      );
    }).toList();
  }

  @override
  Future<void> atualizarStatusPagamento(String vendaId, String status) async {
    await _firestore.collection('vendas').doc(vendaId).update({
      'statusPagamento': status,
      'dataPagamento': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }
}
