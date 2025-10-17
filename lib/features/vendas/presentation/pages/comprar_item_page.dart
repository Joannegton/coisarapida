import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/core/utils/verificacao_helper.dart';
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
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text(
          'Confirmar Compra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.secondary,
                  theme.colorScheme.primary,
                ],
              ),
            ),
          ),
        ),
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
            const SizedBox(height: 100), // Espaço para o botão fixo
          ],
        ),
      ),
      bottomNavigationBar: _buildBotaoPagamento(context, theme, usuario),
    );
  }

  Widget _buildResumoItem(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.item.fotos.isNotEmpty ? widget.item.fotos.first : '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.store,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.item.proprietarioNome,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resumo do Pagamento',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Valor do item',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    'R\$ ${widget.item.precoVenda?.toStringAsFixed(2) ?? '0.00'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total a Pagar',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'R\$ ${widget.item.precoVenda?.toStringAsFixed(2) ?? '0.00'}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecaoPagamento(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Forma de Pagamento',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _metodoPagamento == 'cartao'
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _metodoPagamento == 'cartao'
                    ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                    : null,
              ),
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: _metodoPagamento == 'cartao'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    const Text('Cartão de Crédito'),
                  ],
                ),
                value: 'cartao',
                groupValue: _metodoPagamento,
                onChanged: (value) => setState(() => _metodoPagamento = value!),
                activeColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _metodoPagamento == 'pix'
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _metodoPagamento == 'pix'
                    ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                    : null,
              ),
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(
                      Icons.pix,
                      color: _metodoPagamento == 'pix'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    const Text('PIX'),
                  ],
                ),
                value: 'pix',
                groupValue: _metodoPagamento,
                onChanged: (value) => setState(() => _metodoPagamento = value!),
                activeColor: theme.colorScheme.primary,
              ),
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
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isProcessing
                  ? [
                      Colors.grey.shade400,
                      Colors.grey.shade500,
                    ]
                  : [
                      Colors.green.shade600,
                      Colors.green.shade700,
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: !_isProcessing
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ElevatedButton.icon(
            onPressed:
                _isProcessing ? null : () => _handleProcessarPagamento(comprador),
            icon: _isProcessing
                ? Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.shopping_cart_checkout, size: 24),
            label: Text(
              _isProcessing
                  ? 'Processando...'
                  : 'Confirmar Pagamento - R\$ ${precoVenda.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleProcessarPagamento(Usuario comprador) async {
    // Verificar se usuário está totalmente verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(
        context,
        ref,
        mensagemCustomizada: 'Para realizar compras, você precisa completar as verificações de segurança.',
      );
      return;
    }

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
