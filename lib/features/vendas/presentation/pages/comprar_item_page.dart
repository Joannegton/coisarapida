import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/core/utils/verificacao_helper.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/vendas/domain/entities/venda.dart';
import 'package:coisarapida/features/vendas/presentation/providers/venda_provider.dart';
import 'package:coisarapida/shared/providers/mercado_pago_provider.dart';
import 'package:coisarapida/shared/services/mercado_pago_service.dart';
import 'package:coisarapida/shared/widgets/pagamento_mercado_pago_widget.dart';
import 'package:coisarapida/shared/widgets/tipo_entrega_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:coisarapida/shared/services/payment_deep_link_service.dart';
import 'dart:async';

class ComprarItemPage extends ConsumerStatefulWidget {
  final Item item;

  const ComprarItemPage({super.key, required this.item});

  @override
  ConsumerState<ComprarItemPage> createState() => _ComprarItemPageState();
}

class _ComprarItemPageState extends ConsumerState<ComprarItemPage> {
  String _metodoPagamento = 'mercado_pago';
  bool _isProcessing = false;
  late String _vendaId;
  late Map<String, dynamic> _dadosVenda;

  @override
  void initState() {
    super.initState();
    _vendaId = _gerarIdVenda();
  }

  String _gerarIdVenda() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

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
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text(
          'Confirmar Compra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header com Item
            _buildHeroHeader(context, theme),

            // Conteúdo Principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor do Item',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${widget.item.precoVenda!.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Tipo de entrega
                  SelecaoTipoEntrega(
                    origem: widget.item.localizacao,
                    destino: usuario.endereco,
                    item: widget.item,
                  ),
                  const SizedBox(height: 15),

                  // Segurança
                  const PagamentoMercadoPagoWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBotaoPagamento(context, theme, usuario),
    );
  }

  Widget _buildHeroHeader(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.item.proprietarioNome,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
            onPressed: _isProcessing
                ? null
                : () => _handleProcessarPagamento(comprador),
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
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(
        context,
        ref,
        mensagemCustomizada:
            'Para realizar compras, você precisa completar as verificações de segurança.',
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (widget.item.precoVenda == null) {
        throw 'Preço de venda do item não está definido.';
      }
      _dadosVenda = {
        'vendaId': _vendaId,
        'itemId': widget.item.id,
        'itemNome': widget.item.nome,
        'itemFotoUrl':
            widget.item.fotos.isNotEmpty ? widget.item.fotos.first : '',
        'vendedorId': widget.item.proprietarioId,
        'vendedorNome': widget.item.proprietarioNome,
        'compradorId': comprador.id,
        'compradorNome': comprador.nome,
        'compradorEmail': comprador.email,
        'valorPago': widget.item.precoVenda,
        'metodoPagamento': _metodoPagamento,
        'locadorId': widget.item.proprietarioId,
      };

      await _iniciarPagamentoMercadoPago(comprador, widget.item.precoVenda!);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(context, 'Falha ao processar pagamento: $e');
      }
    } finally {
      if (mounted && _isProcessing) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _iniciarPagamentoMercadoPago(
      Usuario comprador, double valor) async {
    try {
      final venda = Venda(
        id: _vendaId,
        itemId: widget.item.id,
        itemNome: widget.item.nome,
        itemFotoUrl:
            widget.item.fotos.isNotEmpty ? widget.item.fotos.first : '',
        vendedorId: widget.item.proprietarioId,
        vendedorNome: widget.item.proprietarioNome,
        compradorId: comprador.id,
        compradorNome: comprador.nome,
        valorPago: valor,
        metodoPagamento: 'mercado_pago',
        transacaoId: 'pendente', // Será atualizado pelo webhook
        dataVenda: DateTime.now(),
      );

      await ref.read(vendaControllerProvider.notifier).registrarVenda(venda);

      if (!mounted) return;

      final mercadoPagoService = ref.read(mercadoPagoServiceProvider);

      final preferenceResponse =
          await mercadoPagoService.criarPreferenciaPagamento(
        aluguelId: _vendaId,
        valor: valor,
        itemNome: 'Compra - ${_dadosVenda['itemNome']}',
        itemDescricao:
            'Compra de ${_dadosVenda['itemNome']} de ${_dadosVenda['vendedorNome']}',
        locatarioId: comprador.id,
        locadorId: _dadosVenda['vendedorId'] as String,
        locatarioEmail: comprador.email,
        tipo: TipoTransacao.venda,
        locatarioNome: comprador.nome,
        locatarioTelefone: comprador.telefone,
      );

      if (!mounted) return;

      await _abrirCheckoutMercadoPago(
          preferenceResponse['init_point'] as String);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(
          context,
          'Erro ao iniciar pagamento com Mercado Pago: $e',
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  // ignore: unused_element
  Future<void> _abrirCheckoutMercadoPago(String url) async {
    final theme = Theme.of(context);

    try {
      await launchUrl(
        Uri.parse(url),
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: theme.colorScheme.primary,
            navigationBarColor: theme.colorScheme.surface,
          ),
          shareState: CustomTabsShareState.off,
          urlBarHidingEnabled: true,
          showTitle: true,
          closeButton: CustomTabsCloseButton(
            icon: CustomTabsCloseButtonIcons.back,
          ),
          animations: const CustomTabsAnimations(
            startEnter: 'slide_up',
            startExit: 'android:anim/fade_out',
            endEnter: 'android:anim/fade_in',
            endExit: 'slide_down',
          ),
        ),
        safariVCOptions: SafariViewControllerOptions(
          preferredBarTintColor: theme.colorScheme.primary,
          preferredControlTintColor: theme.colorScheme.onPrimary,
          barCollapsingEnabled: true,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );

      // Nota: O retorno será tratado pelo deep link em _handleDeepLink
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(
          context,
          'Erro ao abrir checkout: $e. Verifique se há um navegador instalado.',
        );
        setState(() => _isProcessing = false);
      }
    }
  }
}
