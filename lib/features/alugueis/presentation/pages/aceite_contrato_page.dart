import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';

import '../../../seguranca/presentation/providers/seguranca_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Tela para aceite do contrato digital
class AceiteContratoPage extends ConsumerStatefulWidget {
  final String aluguelId;
  final Map<String, dynamic> dadosAluguel;

  const AceiteContratoPage({
    super.key,
    required this.aluguelId,
    required this.dadosAluguel,
  });

  @override
  ConsumerState<AceiteContratoPage> createState() => _AceiteContratoPageState();
}

class _AceiteContratoPageState extends ConsumerState<AceiteContratoPage> {
  bool _aceiteTermos = false;
  bool _aceiteResponsabilidade = false;
  bool _aceiteCaucao = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Gerar contrato ao inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gerarContrato();
    });
  }

  void _gerarContrato() {
    ref.read(contratoProvider(widget.aluguelId).notifier).gerarContrato(
      locatarioId: widget.dadosAluguel['locatarioId'],
      locadorId: widget.dadosAluguel['locadorId'],
      itemId: widget.dadosAluguel['itemId'],
      dadosAluguel: widget.dadosAluguel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contratoState = ref.watch(contratoProvider(widget.aluguelId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrato de Aluguel'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: contratoState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Erro ao carregar contrato: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _gerarContrato,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
        data: (contrato) {
          if (contrato == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Conteúdo do contrato
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.description,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Contrato Digital',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Leia atentamente antes de aceitar',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Conteúdo HTML do contrato
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Html(
                          data: contrato.conteudoHtml,
                          style: {
                            "body": Style(
                              fontSize: FontSize(14),
                              lineHeight: const LineHeight(1.5),
                            ),
                            ".destaque": Style(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Resumo dos valores
                      _buildResumoValores(),
                      
                      const SizedBox(height: 24),
                      
                      // Checkboxes de aceite
                      _buildCheckboxesAceite(theme),
                    ],
                  ),
                ),
              ),
              
              // Botões de ação
              _buildBotoesAcao(theme, contrato),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumoValores() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo Financeiro',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildLinhaValor('Valor do Aluguel:', 'R\$ ${((widget.dadosAluguel['valorAluguel'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
          _buildLinhaValor('Caução (bloqueada):', 'R\$ ${((widget.dadosAluguel['valorCaucao'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
          _buildLinhaValor('Multa por atraso/dia:', 'R\$ ${((widget.dadosAluguel['valorDiaria'] as num?)?.toDouble() ?? 0.0 * 1.5).toStringAsFixed(2)}'),
          
          const Divider(),
          
          _buildLinhaValor(
            'Total a pagar agora:', 
            'R\$ ${(((widget.dadosAluguel['valorAluguel'] as num?)?.toDouble() ?? 0.0) + ((widget.dadosAluguel['valorCaucao'] as num?)?.toDouble() ?? 0.0)).toStringAsFixed(2)}',
            destaque: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaValor(String label, String valor, {bool destaque = false}) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: destaque ? FontWeight.bold : null,
            ),
          ),
          Text(
            valor,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: destaque ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxesAceite(ThemeData theme) {
    return Column(
      children: [
        CheckboxListTile(
          value: _aceiteTermos,
          onChanged: (value) {
            setState(() {
              _aceiteTermos = value ?? false;
            });
          },
          title: const Text('Li e aceito os termos do contrato'),
          subtitle: const Text('Confirmo que li todo o conteúdo acima'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        
        CheckboxListTile(
          value: _aceiteResponsabilidade,
          onChanged: (value) {
            setState(() {
              _aceiteResponsabilidade = value ?? false;
            });
          },
          title: const Text('Aceito total responsabilidade pelo item'),
          subtitle: const Text('Comprometo-me a devolver em perfeitas condições'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        
        CheckboxListTile(
          value: _aceiteCaucao,
          onChanged: (value) {
            setState(() {
              _aceiteCaucao = value ?? false;
            });
          },
          title: const Text('Autorizo o bloqueio da caução'),
          subtitle: Text('R\$ ${widget.dadosAluguel['valorCaucao']} será bloqueado no meu cartão'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildBotoesAcao(ThemeData theme, contrato) {
    final todosAceitos = _aceiteTermos && _aceiteResponsabilidade && _aceiteCaucao;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Cancelar'),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: todosAceitos ? () => _confirmarAceite(contrato) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: todosAceitos ? theme.colorScheme.primary : null,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Aceitar e Continuar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarAceite(contrato) async {
    // Variável para controlar se o diálogo de loading foi fechado
    bool loadingDialogClosed = false;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog( // Usar dialogContext
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processando aceite...'),
            ],
          ),
        ),
      );

      // Aceitar contrato
      await ref.read(contratoProvider(widget.aluguelId).notifier)
          .aceitarContrato(contrato.id);

      // Não é mais necessário criar uma caução separada aqui.

      // Fechar loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Tentar com rootNavigator
        loadingDialogClosed = true;
      }

      // Mostrar sucesso
      SnackBarUtils.mostrarSucesso(
        context,
        'Contrato aceito com sucesso! ✅',
      );

      // Navegar para próxima tela (caução)
      if (mounted) {
        // Passar os dados do aluguel para a CaucaoPage também
        context.pushReplacement(
          '${AppRoutes.caucao}/${widget.aluguelId}', 
          extra: widget.dadosAluguel);
      }
    } catch (e) {
      // Fechar loading
      debugPrint('[AceiteContratoPage] Erro capturado em _confirmarAceite: $e');
      if (mounted && !loadingDialogClosed) { // Só tenta fechar se não foi fechado no try
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogClosed = true;
      }
      
      SnackBarUtils.mostrarErro(
        context,
        'Erro ao aceitar contrato: $e',
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
