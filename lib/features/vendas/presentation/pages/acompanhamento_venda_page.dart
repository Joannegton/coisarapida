import 'package:flutter/material.dart';

class AcompanhamentoVendaPage extends StatelessWidget {
  final String vendaId;
  final Map<String, dynamic>? dadosVenda;

  const AcompanhamentoVendaPage({
    Key? key,
    required this.vendaId,
    this.dadosVenda,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acompanhamento do Pedido'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag, size: 64, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Pedido realizado com sucesso!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('ID do pedido: $vendaId'),
            if (dadosVenda != null) ...[
              const SizedBox(height: 12),
              Text('Valor pago: R\$ ${dadosVenda!['valorPago'] ?? ''}'),
              Text('Comprador: ${dadosVenda!['compradorNome'] ?? ''}'),
              Text('Vendedor: ${dadosVenda!['vendedorNome'] ?? ''}'),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar para Home'),
            ),
          ],
        ),
      ),
    );
  }
}
