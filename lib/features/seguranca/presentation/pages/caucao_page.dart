import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/seguranca_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/constants/app_routes.dart';

/// Tela para processamento da caução
class CaucaoPage extends ConsumerStatefulWidget {
  final String aluguelId;

  const CaucaoPage({
    super.key,
    required this.aluguelId,
  });

  @override
  ConsumerState<CaucaoPage> createState() => _CaucaoPageState();
}

class _CaucaoPageState extends ConsumerState<CaucaoPage> {
  String _metodoPagamento = 'cartao';
  bool _processandoPagamento = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caucaoState = ref.watch(caucaoProvider(widget.aluguelId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caução do Aluguel'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: caucaoState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Erro ao carregar dados da caução: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(caucaoProvider(widget.aluguelId)),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
        data: (caucao) {
          if (caucao == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho explicativo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.security,
                        size: 48,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Caução de Segurança',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este valor será bloqueado como garantia e liberado após a devolução do item em perfeitas condições.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Detalhes da caução
                _buildDetalhesCaucao(theme, caucao),

                const SizedBox(height: 24),

                // Métodos de pagamento
                _buildMetodosPagamento(theme),

                const SizedBox(height: 24),

                // Termos e condições
                _buildTermosCondicoes(theme),

                const SizedBox(height: 32),

                // Botão de processar
                _buildBotaoProcessar(theme, caucao),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetalhesCaucao(ThemeData theme, caucao) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes da Caução',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildLinhaDetalhe('Item:', caucao.nomeItem),
            _buildLinhaDetalhe('Valor do aluguel:', 'R\$ ${caucao.valorAluguel.toStringAsFixed(2)}'),
            _buildLinhaDetalhe('Período:', '${caucao.diasAluguel} dias'),
            
            const Divider(height: 24),
            
            _buildLinhaDetalhe(
              'Valor da caução:', 
              'R\$ ${caucao.valorCaucao.toStringAsFixed(2)}',
              destaque: true,
            ),
            
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este valor será desbloqueado automaticamente após a confirmação da devolução.',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontSize: 12,
                      ),
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

  Widget _buildLinhaDetalhe(String label, String valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: destaque ? Colors.blue[700] : null,
              fontSize: destaque ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodosPagamento(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Método de Pagamento',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            RadioListTile<String>(
              value: 'cartao',
              groupValue: _metodoPagamento,
              onChanged: (value) {
                setState(() {
                  _metodoPagamento = value!;
                });
              },
              title: const Text('Cartão de Crédito'),
              subtitle: const Text('Bloqueio temporário no cartão'),
              secondary: const Icon(Icons.credit_card),
            ),

            RadioListTile<String>(
              value: 'pix',
              groupValue: _metodoPagamento,
              onChanged: (value) {
                setState(() {
                  _metodoPagamento = value!;
                });
              },
              title: const Text('PIX'),
              subtitle: const Text('Transferência via PIX'),
              secondary: const Icon(Icons.pix),
            ),

            RadioListTile<String>(
              value: 'carteira',
              groupValue: _metodoPagamento,
              onChanged: (value) {
                setState(() {
                  _metodoPagamento = value!;
                });
              },
              title: const Text('Carteira Digital'),
              subtitle: const Text('Saldo da carteira do app'),
              secondary: const Icon(Icons.account_balance_wallet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermosCondicoes(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Condições da Caução',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildCondicaoItem('✅ Liberação automática após devolução aprovada'),
          _buildCondicaoItem('⚠️ Desconto de multas por atraso'),
          _buildCondicaoItem('🔧 Desconto de custos de reparo em caso de danos'),
          _buildCondicaoItem('📅 Prazo máximo de 7 dias para liberação'),
          _buildCondicaoItem('💳 Sem cobrança de juros ou taxas adicionais'),
        ],
      ),
    );
  }

  Widget _buildCondicaoItem(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildBotaoProcessar(ThemeData theme, caucao) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processandoPagamento ? null : () => _processarCaucao(caucao),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _processandoPagamento
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processando...'),
                ],
              )
            : Text(
                'Processar Caução - R\$ ${caucao.valorCaucao.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _processarCaucao(caucao) async {
    setState(() {
      _processandoPagamento = true;
    });

    try {
      // Simular processamento do pagamento
      await Future.delayed(const Duration(seconds: 3));

      // Processar caução
      await ref.read(caucaoProvider(widget.aluguelId).notifier)
          .processarCaucao(
            metodoPagamento: _metodoPagamento,
            valorCaucao: caucao.valorCaucao,
          );

      if (mounted) {
        SnackBarUtils.mostrarSucesso(
          context,
          'Caução processada com sucesso! 🎉',
        );

        // Navegar para status do aluguel
        context.pushReplacement(
          '${AppRoutes.statusAluguel}/${widget.aluguelId}',
          extra: {
            'itemId': caucao.itemId,
            'nomeItem': caucao.nomeItem,
            'valorAluguel': caucao.valorAluguel,
            'valorCaucao': caucao.valorCaucao,
            'dataLimiteDevolucao': DateTime.now().add(Duration(days: caucao.diasAluguel)).toIso8601String(),
            'locadorId': caucao.locadorId,
            'nomeLocador': caucao.nomeLocador,
            'valorDiaria': caucao.valorAluguel / caucao.diasAluguel,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(
          context,
          'Erro ao processar caução: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processandoPagamento = false;
        });
      }
    }
  }
}
