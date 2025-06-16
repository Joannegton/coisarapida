import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// import '../../../seguranca/presentation/providers/seguranca_provider.dart'; // Não mais necessário para caucaoProvider
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/aluguel.dart'; // Importar Aluguel e StatusAluguel
import '../providers/aluguel_providers.dart'; // Para aluguelControllerProvider
import '../../../../core/constants/app_routes.dart';

/// Tela para processamento da caução
class CaucaoPage extends ConsumerStatefulWidget {
  final String aluguelId; // Este será o ID do Aluguel a ser criado
  final Map<String, dynamic> dadosAluguel; // Dados passados da AceiteContratoPage

  const CaucaoPage({
    super.key,
    required this.aluguelId,
    required this.dadosAluguel,
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
    // Não há mais um 'caucaoState' separado. Os dados vêm de widget.dadosAluguel.
    final valorCaucao = (widget.dadosAluguel['valorCaucao'] as num?)?.toDouble() ?? 0.0;
    final nomeItem = widget.dadosAluguel['nomeItem'] as String? ?? 'Item não especificado';
    final valorAluguel = (widget.dadosAluguel['valorAluguel'] as num?)?.toDouble() ?? 0.0;
    final dataInicio = DateTime.parse(widget.dadosAluguel['dataInicio'] as String);
    final dataFim = DateTime.parse(widget.dadosAluguel['dataFim'] as String);
    final diasAluguel = dataFim.difference(dataInicio).inDays > 0 ? dataFim.difference(dataInicio).inDays : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caução do Aluguel'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SingleChildScrollView(
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
                _buildDetalhesCaucao(
                  theme, 
                  nomeItem, 
                  valorAluguel, 
                  diasAluguel, 
                  valorCaucao
                ),

                const SizedBox(height: 24),

                // Métodos de pagamento
                _buildMetodosPagamento(theme),

                const SizedBox(height: 24),

                // Termos e condições
                _buildTermosCondicoes(theme),

                const SizedBox(height: 32),

                // Botão de processar
                _buildBotaoProcessar(theme, valorCaucao),
              ],
            ),
          ),
    );
  }

  Widget _buildDetalhesCaucao(ThemeData theme, String nomeItem, double valorAluguel, int diasAluguel, double valorCaucao) {
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

            _buildLinhaDetalhe('Item:', nomeItem),
            _buildLinhaDetalhe('Valor do aluguel:', 'R\$ ${valorAluguel.toStringAsFixed(2)}'),
            _buildLinhaDetalhe('Período:', '$diasAluguel dias'),
            
            const Divider(height: 24),
            
            _buildLinhaDetalhe(
              'Valor da caução:', 
              'R\$ ${valorCaucao.toStringAsFixed(2)}',
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

  Widget _buildBotaoProcessar(ThemeData theme, double valorCaucao) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processandoPagamento || valorCaucao <= 0 ? null : _processarCaucao,
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
                valorCaucao > 0 ? 'Processar Caução - R\$ ${valorCaucao.toStringAsFixed(2)}' : 'Continuar (Sem Caução)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _processarCaucao() async {
    setState(() {
      _processandoPagamento = true;
    });

    final String transacaoIdSimulada = 'TXN_SIM_${DateTime.now().millisecondsSinceEpoch}';
    final valorCaucao = (widget.dadosAluguel['valorCaucao'] as num?)?.toDouble() ?? 0.0;

    try {
      if (valorCaucao > 0) {
        // Simular processamento do pagamento
        await Future.delayed(const Duration(seconds: 3)); 
        // Aqui ocorreria a chamada ao AluguelController para registrar o pagamento da caução no Aluguel
        // Isso será feito ao criar o Aluguel.
      }

      // Construir o objeto Aluguel
      final aluguelParaSalvar = Aluguel(
        id: widget.aluguelId,
        itemId: widget.dadosAluguel['itemId'] as String,
        itemFotoUrl: widget.dadosAluguel['itemFotoUrl'] as String? ?? '',
        itemNome: widget.dadosAluguel['nomeItem'] as String,
        locadorId: widget.dadosAluguel['locadorId'] as String,
        locadorNome: widget.dadosAluguel['nomeLocador'] as String,
        locatarioId: widget.dadosAluguel['locatarioId'] as String,
        locatarioNome: widget.dadosAluguel['nomeLocatario'] as String,
        dataInicio: DateTime.parse(widget.dadosAluguel['dataInicio'] as String),
        dataFim: DateTime.parse(widget.dadosAluguel['dataFim'] as String),
        precoTotal: (widget.dadosAluguel['valorAluguel'] as num).toDouble(),
        status: StatusAluguel.solicitado,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
        observacoesLocatario: widget.dadosAluguel['observacoesLocatario'] as String?,
        contratoId: widget.aluguelId, // Assumindo que o contratoId é o mesmo que aluguelId por simplicidade
        caucaoValor: valorCaucao,
        caucaoStatus: valorCaucao > 0 ? StatusCaucaoAluguel.bloqueada : StatusCaucaoAluguel.naoAplicavel,
        caucaoMetodoPagamento: valorCaucao > 0 ? _metodoPagamento : null,
        caucaoTransacaoId: valorCaucao > 0 ? transacaoIdSimulada : null,
        caucaoDataBloqueio: valorCaucao > 0 ? DateTime.now() : null, // O Firestore usará FieldValue.serverTimestamp
      );

      // Se a caução foi "paga", chamar o controller para atualizar o aluguel com os dados da caução
      // Esta etapa é agora combinada com a submissão do aluguel.
      // O AluguelController.submeterAluguelCompleto já recebe o objeto Aluguel com os dados da caução.

      // Salvar a solicitação de aluguel
      await ref.read(aluguelControllerProvider.notifier).submeterAluguelCompleto(aluguelParaSalvar);

      if (mounted) {
        SnackBarUtils.mostrarSucesso(
          context,
          valorCaucao > 0 
            ? 'Caução processada e solicitação de aluguel enviada! 🎉'
            : 'Solicitação de aluguel enviada! 🎉',
        );

        // Navegar para status do aluguel
        // Os dados passados para StatusAluguelPage precisam ser consistentes
        final dadosParaStatus = {
          'itemId': aluguelParaSalvar.itemId,
          'nomeItem': aluguelParaSalvar.itemNome,
          'valorAluguel': aluguelParaSalvar.precoTotal,
          'valorCaucao': aluguelParaSalvar.caucaoValor ?? 0.0,
          'dataLimiteDevolucao': aluguelParaSalvar.dataFim.toIso8601String(),
          'locadorId': aluguelParaSalvar.locadorId,
          'nomeLocador': aluguelParaSalvar.locadorNome,
          // 'valorDiaria' precisa vir de dadosFluxo se for usado em StatusAluguelPage
          'valorDiaria': (widget.dadosAluguel['valorDiaria'] as num?)?.toDouble() ?? (aluguelParaSalvar.precoTotal / (aluguelParaSalvar.dataFim.difference(aluguelParaSalvar.dataInicio).inDays > 0 ? aluguelParaSalvar.dataFim.difference(aluguelParaSalvar.dataInicio).inDays : 1) ),
        };

         context.pushReplacement(
          '${AppRoutes.statusAluguel}/${widget.aluguelId}',
          extra: dadosParaStatus,
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
