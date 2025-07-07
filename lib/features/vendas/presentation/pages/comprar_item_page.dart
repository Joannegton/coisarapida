import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/vendas/domain/entities/venda.dart';
import 'package:coisarapida/features/vendas/presentation/providers/venda_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ComprarItemPage extends ConsumerStatefulWidget {
  final Item item;

  const ComprarItemPage({super.key, required this.item});

  @override
  ConsumerState<ComprarItemPage> createState() => _ComprarItemPageState();
}

class _ComprarItemPageState extends ConsumerState<ComprarItemPage> {
  String _metodoPagamento = 'cartao';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuario = ref.watch(usuarioAtualStreamProvider).value;

    if (usuario == null) {
      // Idealmente, o GoRouter deveria proteger esta rota, mas é uma boa segurança.
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Compra'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumoItem(context, theme),
            const SizedBox(height: 24),
            _buildDetalhesPagamento(context, theme),
            const SizedBox(height: 24),
            _buildSelecaoPagamento(context, theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildBotaoPagamento(context, theme, usuario),
    );
  }

  Widget _buildResumoItem(BuildContext context, ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.item.fotos.isNotEmpty ? widget.item.fotos.first : '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.nome,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vendido por: ${widget.item.proprietarioNome}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalhesPagamento(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo do Pagamento', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Valor do item'),
                Text(
                  'R\$ ${widget.item.precoVenda?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total a Pagar', style: theme.textTheme.titleMedium),
                Text(
                  'R\$ ${widget.item.precoVenda?.toStringAsFixed(2) ?? '0.00'}',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecaoPagamento(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Forma de Pagamento', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('Cartão de Crédito'),
              value: 'cartao',
              groupValue: _metodoPagamento,
              onChanged: (value) => setState(() => _metodoPagamento = value!),
            ),
            RadioListTile<String>(
              title: const Text('PIX'),
              value: 'pix',
              groupValue: _metodoPagamento,
              onChanged: (value) => setState(() => _metodoPagamento = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoPagamento(
      BuildContext context, ThemeData theme, Usuario comprador) {
    final precoVenda = widget.item.precoVenda ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        onPressed:
            _isProcessing ? null : () => _handleProcessarPagamento(comprador),
        icon: _isProcessing
            ? Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary)),
              )
            : const Icon(Icons.shopping_cart_checkout),
        label: Text(_isProcessing
            ? 'Processando...'
            : 'Pagar R\$ ${precoVenda.toStringAsFixed(2)}'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green.shade700,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Future<void> _handleProcessarPagamento(Usuario comprador) async {
    setState(() => _isProcessing = true);

    try {
      final transacaoIdSimulada =
          'TXN_COMPRA_${DateTime.now().millisecondsSinceEpoch}';

      final venda = Venda(
        id: '', // O ID será gerado pelo Firestore
        itemId: widget.item.id,
        itemNome: widget.item.nome,
        itemFotoUrl:
            widget.item.fotos.isNotEmpty ? widget.item.fotos.first : '',
        vendedorId: widget.item.proprietarioId,
        vendedorNome: widget.item.proprietarioNome,
        compradorId: comprador.id,
        compradorNome: comprador.nome,
        valorPago: widget.item.precoVenda!,
        metodoPagamento: _metodoPagamento,
        transacaoId: transacaoIdSimulada,
        dataVenda: DateTime.now(),
      );

      await ref.read(vendaControllerProvider.notifier).registrarVenda(venda);

      if (mounted) {
        SnackBarUtils.mostrarSucesso(
            context, 'Compra realizada com sucesso! 🎉');
        // Navega para a home ou para uma página de "Minhas Compras"
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(context, 'Falha ao processar pagamento: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
