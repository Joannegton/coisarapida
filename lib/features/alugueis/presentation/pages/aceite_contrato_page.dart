import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../seguranca/presentation/providers/seguranca_provider.dart';

/// Tela para aceite do contrato digital
class AceiteContratoPage extends ConsumerStatefulWidget {
  final String aluguelId;
  final Map<String, dynamic> dadosAluguel;

  // Callbacks para notificar o pai sobre mudanças no estado dos checkboxes
  final ValueChanged<bool> onAceiteTermosChanged;
  final ValueChanged<bool> onAceiteResponsabilidadeChanged;
  final ValueChanged<bool> onAceiteCaucaoChanged;

  // Estado atual dos checkboxes, passado do pai
  final bool aceiteTermos;
  final bool aceiteResponsabilidade;
  final bool aceiteCaucao;

  const AceiteContratoPage({
    super.key,
    required this.aluguelId, required this.dadosAluguel,
    required this.onAceiteTermosChanged, required this.onAceiteResponsabilidadeChanged, required this.onAceiteCaucaoChanged,
    required this.aceiteTermos, required this.aceiteResponsabilidade, required this.aceiteCaucao,
  });

  @override
  ConsumerState<AceiteContratoPage> createState() => _AceiteContratoPageState();
}

class _AceiteContratoPageState extends ConsumerState<AceiteContratoPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // gera contrato ao inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gerarContrato();
    });
  }

  @override
  Widget build(BuildContext context) {
    final contratoState = ref.watch(contratoProvider(widget.aluguelId));
    final theme = Theme.of(context);

    return contratoState.when(
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
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Html(
                          data: contrato.conteudoHtml,
                          style: {
                            "body": Style(
                              fontFamily: 'Arial',
                              margin: Margins.all(30.0),
                              lineHeight: const LineHeight(1.6),
                              color: theme.colorScheme.onSurface,
                              fontSize: FontSize(14),
                            ),
                            ".header": Style(
                              textAlign: TextAlign.center,
                              margin: Margins.only(bottom: 30.0),
                            ),
                            "h2": Style(
                              color: theme.colorScheme.error,
                              margin: Margins.only(bottom: 5.0),
                            ),
                            "h3": Style(
                              color: theme.colorScheme.error,
                              margin: Margins.only(bottom: 5.0),
                            ),
                            "h4": Style(
                              color: theme.colorScheme.onSurfaceVariant,
                              margin: Margins.only(bottom: 10.0),
                              border: Border(bottom: BorderSide(color: theme.colorScheme.outline, width: 1.0)),
                              padding: HtmlPaddings.only(bottom: 5.0),
                            ),
                            "ul": Style(
                              margin: Margins.only(left: 20.0),
                            ),
                            ".destaque": Style(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                            ".assinaturas": Style(
                              margin: Margins.only(top: 40.0),
                              textAlign: TextAlign.center,
                            ),
                            ".assinaturas div": Style(
                              display: Display.inlineBlock,
                              margin: Margins.symmetric(horizontal: 40.0),
                            ),
                            ".assinaturas p": Style(
                              margin: Margins.only(top: 5.0),
                              border: Border(top: BorderSide(color: theme.colorScheme.onSurface, width: 1.0)),
                              padding: HtmlPaddings.only(top: 5.0),
                            ),
                            ".footer": Style(
                              margin: Margins.only(top: 30.0),
                              fontSize: FontSize(12),
                              color: theme.colorScheme.onSurfaceVariant,
                              textAlign: TextAlign.center,
                              border: Border(top: BorderSide(color: theme.colorScheme.outline, width: 1.0)),
                              padding: HtmlPaddings.only(top: 10.0),
                            ),
                            ".section": Style(
                              margin: Margins.only(bottom: 20.0),
                            ),
                            ".metadata": Style(
                              fontSize: FontSize(11),
                              color: theme.colorScheme.onSurfaceVariant,
                              margin: Margins.only(top: 5.0),
                            ),
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildResumoValores(theme),
                      
                      const SizedBox(height: 24),
                      
                      _buildCheckboxesAceite(theme),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
    );
  }

  double _getDadosAluguelDouble(String key) => (widget.dadosAluguel[key] as num?)?.toDouble() ?? 0.0;

  Widget _buildResumoValores(ThemeData theme) {
    final valorAluguel = _getDadosAluguelDouble('valorAluguel');
    final valorCaucao = _getDadosAluguelDouble('valorCaucao');
    final valorDiaria = _getDadosAluguelDouble('valorDiaria');
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
          
          _buildLinhaValor(theme, 'Valor do Aluguel:', 'R\$ ${valorAluguel.toStringAsFixed(2)}'),
          _buildLinhaValor(theme, 'Caução (bloqueada):', 'R\$ ${valorCaucao.toStringAsFixed(2)}'),
          _buildLinhaValor(theme, 'Multa por atraso/dia:', 'R\$ ${(valorDiaria * 1.5).toStringAsFixed(2)}'),
          
          const Divider(),
          
          _buildLinhaValor(
            theme,
            'Total a pagar agora:',
            'R\$ ${(valorAluguel + valorCaucao).toStringAsFixed(2)}',
            destaque: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLinhaValor(ThemeData theme, String label, String valor, {bool destaque = false}) {
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
          value: widget.aceiteTermos,
          onChanged: (value) {
            widget.onAceiteTermosChanged(value ?? false);
          },
          title: const Text('Li e aceito os termos do contrato'),
          subtitle: const Text('Confirmo que li todo o conteúdo acima'),
          controlAffinity: ListTileControlAffinity.leading,
        ),

        CheckboxListTile(
          value: widget.aceiteResponsabilidade,
          onChanged: (value) {
            widget.onAceiteResponsabilidadeChanged(value ?? false);
          },
          title: const Text('Aceito total responsabilidade pelo item'),
          subtitle: const Text('Comprometo-me a devolver em perfeitas condições'),
          controlAffinity: ListTileControlAffinity.leading,
        ),

        CheckboxListTile(
          value: widget.aceiteCaucao,
          onChanged: (value) {
            widget.onAceiteCaucaoChanged(value ?? false);
          },
          title: const Text('Autorizo o bloqueio da caução'),
          subtitle: Text('R\$ ${widget.dadosAluguel['valorCaucao']} será bloqueado no meu cartão'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
